import fs from "node:fs/promises";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

import { env } from "../src/config/env.js";
import { query, closeDatabase } from "../src/db/pool.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const migrationsDirectory = path.resolve(
  __dirname,
  "../db/migrations"
);

const hash = (content) => {
  return crypto
    .createHash("sha256")
    .update(content)
    .digest("hex");
};

const main = async () => {
  if (!env.databaseUrl) {
    throw new Error(
      "DATABASE_URL is not configured"
    );
  }

  await query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id BIGSERIAL PRIMARY KEY,
      filename VARCHAR(255) NOT NULL UNIQUE,
      checksum_sha256 CHAR(64),
      applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);

  const files = await fs.readdir(
    migrationsDirectory
  );

  const migrations = files
    .filter((file) => file.endsWith(".sql"))
    .sort();

  const appliedResult = await query(`
    SELECT filename, checksum_sha256
    FROM schema_migrations
    ORDER BY filename
  `);

  const applied = new Map(
    appliedResult.rows.map((row) => [
      row.filename,
      row.checksum_sha256
    ])
  );

  for (const filename of migrations) {
    const fullPath = path.join(
      migrationsDirectory,
      filename
    );

    const content = await fs.readFile(
      fullPath,
      "utf8"
    );

    const checksum = hash(content);

    if (applied.has(filename)) {
      const previousChecksum = applied.get(filename);

      if (
        previousChecksum &&
        previousChecksum !== checksum
      ) {
        throw new Error(
          `Migration checksum mismatch: ${filename}`
        );
      }

      console.log(
        `[MIGRATION] Already applied: ${filename}`
      );

      continue;
    }

    console.log(
      `[MIGRATION] Applying: ${filename}`
    );

    await query("BEGIN");

    try {
      await query(content);

      await query(
        `
          INSERT INTO schema_migrations
            (filename, checksum_sha256)
          VALUES
            ($1, $2)
        `,
        [filename, checksum]
      );

      await query("COMMIT");

      console.log(
        `[MIGRATION] Applied: ${filename}`
      );
    } catch (error) {
      await query("ROLLBACK");

      throw error;
    }
  }

  console.log(
    `[MIGRATION] Complete. ${migrations.length} migration(s) checked.`
  );
};

main()
  .catch((error) => {
    console.error(
      "[MIGRATION ERROR]",
      error
    );

    process.exitCode = 1;
  })
  .finally(async () => {
    await closeDatabase();
  });