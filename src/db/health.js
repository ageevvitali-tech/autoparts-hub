import {
  isDatabaseConfigured,
  query
} from "./pool.js";

export const checkDatabaseHealth = async () => {
  if (!isDatabaseConfigured()) {
    return {
      configured: false,
      connected: false,
      message: "DATABASE_URL is not configured"
    };
  }

  try {
    const result = await query(
      "SELECT NOW() AS current_time"
    );

    return {
      configured: true,
      connected: true,
      currentTime: result.rows[0].current_time
    };
  } catch (error) {
    return {
      configured: true,
      connected: false,
      message: error.message
    };
  }
};