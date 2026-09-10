import pg from "pg";

import { env } from "../config/env.js";

const { Pool } = pg;

let pool = null;

if (env.databaseUrl) {
  pool = new Pool({
    connectionString: env.databaseUrl,

    max: 10,

    idleTimeoutMillis: 30_000,

    connectionTimeoutMillis: 5_000,

    ssl:
      env.nodeEnv === "production"
        ? {
            rejectUnauthorized: false
          }
        : false
  });

  pool.on("error", (error) => {
    console.error("[PostgreSQL] Unexpected pool error", error);
  });
}

export const isDatabaseConfigured = () => {
  return Boolean(pool);
};

export const query = async (text, params = []) => {
  if (!pool) {
    throw new Error("DATABASE_URL is not configured");
  }

  return pool.query(text, params);
};

export const getPool = () => {
  return pool;
};

export const closeDatabase = async () => {
  if (!pool) {
    return;
  }

  await pool.end();
  pool = null;
};