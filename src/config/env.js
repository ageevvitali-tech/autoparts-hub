import "dotenv/config";

const toNumber = (value, fallback) => {
  const number = Number(value);

  return Number.isFinite(number) ? number : fallback;
};

export const env = Object.freeze({
  nodeEnv: process.env.NODE_ENV || "development",

  port: toNumber(process.env.PORT, 3000),

  databaseUrl: process.env.DATABASE_URL || "",

  elasticsearchUrl: process.env.ELASTICSEARCH_URL || "",
  elasticsearchUsername: process.env.ELASTICSEARCH_USERNAME || "",
  elasticsearchPassword: process.env.ELASTICSEARCH_PASSWORD || "",

  jwtSecret: process.env.JWT_SECRET || "",
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET || "",

  tecdocApiUrl: process.env.TECDOC_API_URL || "",
  tecdocApiKey: process.env.TECDOC_API_KEY || "",

  telegramBotToken: process.env.TELEGRAM_BOT_TOKEN || "",

  aiApiKey: process.env.AI_API_KEY || ""
});