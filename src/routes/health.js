import { Router } from "express";

import { env } from "../config/env.js";
import { checkDatabaseHealth } from "../db/health.js";

const router = Router();

router.get("/", async (_req, res) => {
  const database = await checkDatabaseHealth();

  const overallOk =
    database.connected || !database.configured;

  res.status(overallOk ? 200 : 503).json({
    ok: overallOk,

    service: "autoparts-hub",

    version: "1.0.0",

    environment: env.nodeEnv,

    timestamp: new Date().toISOString(),

    database
  });
});

export default router;