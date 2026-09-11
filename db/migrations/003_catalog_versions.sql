/*
========================================================
 AUTOPARTS HUB
 Migration 003
 Catalog imports and versions
========================================================
*/

BEGIN;


/*
--------------------------------------------------------
 CATALOG VERSIONS
--------------------------------------------------------
*/

CREATE TABLE IF NOT EXISTS catalog_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    source_id UUID NOT NULL
        REFERENCES data_sources(id)
        ON DELETE RESTRICT,

    version VARCHAR(100) NOT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'created',

    started_at TIMESTAMPTZ,

    completed_at TIMESTAMPTZ,

    records_received BIGINT NOT NULL DEFAULT 0,

    records_imported BIGINT NOT NULL DEFAULT 0,

    records_updated BIGINT NOT NULL DEFAULT 0,

    records_rejected BIGINT NOT NULL DEFAULT 0,

    error_count BIGINT NOT NULL DEFAULT 0,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT catalog_versions_status_check
        CHECK (
            status IN (
                'created',
                'processing',
                'validated',
                'active',
                'failed',
                'rolled_back'
            )
        )
);


/*
--------------------------------------------------------
 INDEXES
--------------------------------------------------------
*/

CREATE INDEX IF NOT EXISTS idx_catalog_versions_source
    ON catalog_versions(source_id);

CREATE INDEX IF NOT EXISTS idx_catalog_versions_status
    ON catalog_versions(status);

CREATE INDEX IF NOT EXISTS idx_catalog_versions_created
    ON catalog_versions(created_at);


/*
--------------------------------------------------------
 UNIQUE VERSION PER SOURCE
--------------------------------------------------------
*/

CREATE UNIQUE INDEX IF NOT EXISTS
idx_catalog_versions_source_version
ON catalog_versions(source_id, version);


COMMIT;