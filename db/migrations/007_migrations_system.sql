CREATE TABLE IF NOT EXISTS schema_migrations (
    id BIGSERIAL PRIMARY KEY,

    filename VARCHAR(255) NOT NULL UNIQUE,

    checksum_sha256 CHAR(64),

    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_schema_migrations_filename
    ON schema_migrations(filename);