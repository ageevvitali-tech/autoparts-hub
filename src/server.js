import crypto from "node:crypto";
import express from "express";
import cors from "cors";
import helmet from "helmet";

import { env } from "./config/env.js";
import healthRouter from "./routes/health.js";

const app = express();

/*
 * ======================================================
 * AUTOPARTS HUB
 * Main application server
 * ======================================================
 */

/*
 * ------------------------------------------------------
 * Security
 * ------------------------------------------------------
 */

app.disable("x-powered-by");

app.use(
  helmet({
    crossOriginResourcePolicy: {
      policy: "cross-origin"
    }
  })
);

/*
 * ------------------------------------------------------
 * CORS
 * ------------------------------------------------------
 */

app.use(
  cors({
    origin: true,
    credentials: true
  })
);

/*
 * ------------------------------------------------------
 * Request body limits
 * ------------------------------------------------------
 */

app.use(
  express.json({
    limit: "1mb"
  })
);

app.use(
  express.urlencoded({
    extended: false,
    limit: "1mb"
  })
);

/*
 * ------------------------------------------------------
 * Request ID
 * ------------------------------------------------------
 */

app.use((req, res, next) => {
  const requestId = crypto.randomUUID();

  req.requestId = requestId;

  res.setHeader("X-Request-ID", requestId);

  next();
});

/*
 * ------------------------------------------------------
 * API
 * ------------------------------------------------------
 */

app.use("/api/health", healthRouter);

/*
 * ------------------------------------------------------
 * API 404
 * ------------------------------------------------------
 */

app.use("/api", (req, res) => {
  res.status(404).json({
    ok: false,
    error: {
      code: "API_NOT_FOUND",
      message: "API endpoint not found",
      path: req.originalUrl
    },
    requestId: req.requestId
  });
});

/*
 * ------------------------------------------------------
 * Global error handler
 * ------------------------------------------------------
 */

app.use((error, req, res, _next) => {
  console.error("[API ERROR]", {
    requestId: req.requestId,
    message: error.message,
    stack: env.nodeEnv === "development"
      ? error.stack
      : undefined
  });

  if (res.headersSent) {
    return;
  }

  res.status(500).json({
    ok: false,
    error: {
      code: "INTERNAL_SERVER_ERROR",
      message: "Internal server error"
    },
    requestId: req.requestId
  });
});

/*
 * ------------------------------------------------------
 * Start server
 * ------------------------------------------------------
 */

const server = app.listen(env.port, "0.0.0.0", () => {
  console.log(
    `[AutoParts Hub] Server started`
  );

  console.log(
    `[AutoParts Hub] Port: ${env.port}`
  );

  console.log(
    `[AutoParts Hub] Environment: ${env.nodeEnv}`
  );
});

/*
 * ------------------------------------------------------
 * Graceful shutdown
 * ------------------------------------------------------
 */

const shutdown = (signal) => {
  console.log(
    `[AutoParts Hub] Received ${signal}`
  );

  server.close(() => {
    console.log(
      "[AutoParts Hub] Server stopped"
    );

    process.exit(0);
  });
};

process.on("SIGTERM", () => {
  shutdown("SIGTERM");
});

process.on("SIGINT", () => {
  shutdown("SIGINT");
});