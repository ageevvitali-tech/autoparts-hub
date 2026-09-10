import { Router } from "express";

const router = Router();

router.get("/", (_req, res) => {
  res.status(200).json({
    ok: true,
    service: "autoparts-hub",
    version: "1.0.0",
    environment: process.env.NODE_ENV || "development",
    timestamp: new Date().toISOString()
  });
});

export default router;