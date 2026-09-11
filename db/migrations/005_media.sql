CREATE TABLE IF NOT EXISTS media_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    media_type VARCHAR(30) NOT NULL
        CHECK (
            media_type IN (
                'part_image',
                'diagram',
                'document'
            )
        ),

    part_id UUID REFERENCES parts(id) ON DELETE CASCADE,

    storage_key TEXT NOT NULL,
    original_filename TEXT,

    mime_type VARCHAR(100),
    file_size_bytes BIGINT,

    width INTEGER,
    height INTEGER,

    checksum_sha256 CHAR(64),

    title TEXT,
    alt_text TEXT,

    source_id UUID REFERENCES data_sources(id) ON DELETE SET NULL,

    copyright_holder TEXT,
    license TEXT,

    sort_order INTEGER NOT NULL DEFAULT 0,

    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_media_assets_part
    ON media_assets(part_id);

CREATE INDEX IF NOT EXISTS idx_media_assets_type
    ON media_assets(media_type);

CREATE INDEX IF NOT EXISTS idx_media_assets_checksum
    ON media_assets(checksum_sha256);

CREATE INDEX IF NOT EXISTS idx_media_assets_active
    ON media_assets(is_active);

CREATE UNIQUE INDEX IF NOT EXISTS ux_media_assets_storage_key
    ON media_assets(storage_key);

CREATE OR REPLACE FUNCTION set_media_assets_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_media_assets_updated_at
ON media_assets;

CREATE TRIGGER trg_media_assets_updated_at
BEFORE UPDATE ON media_assets
FOR EACH ROW
EXECUTE FUNCTION set_media_assets_updated_at();