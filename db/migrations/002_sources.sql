/*
========================================================
 AUTOPARTS HUB
 Migration 002
 Data sources and catalog provenance
========================================================
*/

BEGIN;


/*
--------------------------------------------------------
 DATA SOURCES
--------------------------------------------------------
*/

CREATE TABLE IF NOT EXISTS data_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(200) NOT NULL,

    source_type VARCHAR(40) NOT NULL,

    provider VARCHAR(200),

    external_id VARCHAR(200),

    description TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT data_sources_type_check
        CHECK (
            source_type IN (
                'tecdoc',
                'oem',
                'supplier',
                'manufacturer',
                'manual',
                'user',
                'ai',
                'import'
            )
        )
);


/*
--------------------------------------------------------
 ADD SOURCE REFERENCES
--------------------------------------------------------
*/

ALTER TABLE part_numbers
    ADD CONSTRAINT fk_part_numbers_source
    FOREIGN KEY (source_id)
    REFERENCES data_sources(id)
    ON DELETE SET NULL;


ALTER TABLE part_relations
    ADD CONSTRAINT fk_part_relations_source
    FOREIGN KEY (source_id)
    REFERENCES data_sources(id)
    ON DELETE SET NULL;


ALTER TABLE fitments
    ADD CONSTRAINT fk_fitments_source
    FOREIGN KEY (source_id)
    REFERENCES data_sources(id)
    ON DELETE SET NULL;


/*
--------------------------------------------------------
 INDEXES
--------------------------------------------------------
*/

CREATE INDEX IF NOT EXISTS idx_data_sources_type
    ON data_sources(source_type);

CREATE INDEX IF NOT EXISTS idx_data_sources_external_id
    ON data_sources(external_id);


/*
--------------------------------------------------------
 UPDATED_AT
--------------------------------------------------------
*/

DROP TRIGGER IF EXISTS data_sources_updated_at
ON data_sources;

CREATE TRIGGER data_sources_updated_at
BEFORE UPDATE ON data_sources
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


COMMIT;