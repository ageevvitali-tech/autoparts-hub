import app from "./app.js";
import { env } from "./config/env.js";

const server = app.listen(env.port, "0.0.0.0", () => {
  console.log("[AutoParts Hub] Server started");
  console.log(`[AutoParts Hub] Port: ${env.port}`);
  console.log(`[AutoParts Hub] Environment: ${env.nodeEnv}`);
});

const shutdown = (signal) => {
  console.log(`[AutoParts Hub] Received ${signal}`);

  server.close(() => {
    console.log("[AutoParts Hub] Server stopped");
    process.exit(0);
  });
};

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));