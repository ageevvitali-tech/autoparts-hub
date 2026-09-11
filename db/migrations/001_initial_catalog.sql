/*
========================================================
 AUTOPARTS HUB
 Migration 001
 Initial catalog foundation
========================================================
*/

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;


/*
--------------------------------------------------------
 BRANDS
--------------------------------------------------------
*/

CREATE TABLE IF NOT EXISTS brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(200) NOT NULL,
    normalized_name VARCHAR(200) NOT NULL,

    country_code VARCHAR(10),

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT brands_name_unique
        UNIQUE (normalized_name)
);


/*
--------------------------------------------------------
 CATEGORIES
--------------------------------------------------------
*/

CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    parent_id UUID REFERENCES categories(id)
        ON DELETE SET NULL,

    name VARCHAR(200) NOT NULL,
    normalized_name VARCHAR(200) NOT NULL,

    slug VARCHAR(220) NOT NULL,

    description TEXT,

    sort_order INTEGER NOT NULL DEFAULT 0,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT categories_slug_unique
        UNIQUE (slug)
);


/*
--------------------------------------------------------
 PARTS
 Canonical automotive part
--------------------------------------------------------
*/

CREATE TABLE IF NOT EXISTS parts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    brand_id UUID NOT NULL
        REFERENCES brands(id)
        ON DELETE RESTRICT,

    category_id UUID
        REFERENCES categories(id)
        ON DELETE SET NULL,

    name VARCHAR(500) NOT NULL,

    normalized_name VARCHAR(500) NOT NULL,

    description TEXT,

    status VARCHAR(30) NOT NULL DEFAULT 'active',

    data_quality_score NUMERIC(5,2)
        NOT NULL DEFAULT 0
        CHECK (
            data_quality_score >= 0
            AND data_quality_score <= 100
        ),

    confidence_score NUMERIC(5,2)
        NOT NULL DEFAULT 0
        CHECK (
            confidence_score >= 0
            AND confidence_score <= 100
        ),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT parts_status_check
        CHECK (
            status IN (
                'draft',
                'active',
                'inactive',
                'archived'
            )
        )
);


/*
--------------------------------------------------------
 PART NUMBERS
 Article / OE / OEM / cross / supplier numbers
--------------------------------------------------------
*/

CREATE TABLE IF NOT EXISTS part_numbers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    part_id UUID NOT NULL
        REFERENCES parts(id)
        ON DELETE CASCADE,

    number VARCHAR(200) NOT NULL,

    normalized_number VARCHAR(200) NOT NULL,

    number_type VARCHAR(30) NOT NULL,

    manufacturer_id UUID
        REFERENCES brands(id)
        ON DELETE SET NULL,

    is_primary BOOLEAN NOT NULL DEFAULT FALSE,

    source_id UUID,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT part_numbers_type_check
        CHECK (
            number_type IN (
                'article',
                'oe',
                'oem',
                'cross',
                'supplier',
                'internal'
            )
        )
);


/*
--------------------------------------------------------
 PART RELATIONS
 Analog / replacement / supersession / cross
--------------------------------------------------------
*/

CREATE TABLE IF NOT EXISTS part_relations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    source_part_id UUID NOT NULL
        REFERENCES parts(id)
        ON DELETE CASCADE,

    target_part_id UUID NOT NULL
        REFERENCES parts(id)
        ON DELETE CASCADE,

    relation_type VARCHAR(40) NOT NULL,

    confidence_score NUMERIC(5,2)
        NOT NULL DEFAULT 0
        CHECK (
            confidence_score >= 0
            AND confidence_score <= 100
        ),

    source_id UUID,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT part_relations_type_check
        CHECK (
            relation_type IN (
                'cross',
                'analog',
                'replacement',
                'supersedes',
                'equivalent',
                'kit_component'
            )
        ),

    CONSTRAINT part_relations_no_self
        CHECK (source_part_id <> target_part_id),

    CONSTRAINT part_relations_unique
        UNIQUE (
            source_part_id,
            target_part_id,
            relation_type
        )
);


/*
--------------------------------------------------------
 VEHICLE MAKES
--------------------------------------------------------
*/

CREATE TABLE IF NOT EXISTS vehicle_makes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(200) NOT NULL,
    normalized_name VARCHAR(200) NOT NULL,

    vehicle_type VARCHAR(40) NOT NULL DEFAULT 'passenger',

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT vehicle_makes_type_check
        CHECK (
            vehicle_type IN (
                'passenger',
                'commercial',
                'truck',
                'tractor',
                'bus',
                'motorcycle',
                'trailer',
                'special'
            )
        ),

    CONSTRAINT vehicle_makes_unique
        UNIQUE (normalized_name)
);


/*
--------------------------------------------------------
 VEHICLE MODELS
--------------------------------------------------------
*/

CREATE TABLE IF NOT EXISTS vehicle_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    make_id UUID NOT NULL
        REFERENCES vehicle_makes(id)
        ON DELETE CASCADE,

    name VARCHAR(200) NOT NULL,
    normalized_name VARCHAR(200) NOT NULL,

    slug VARCHAR(220),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


/*
--------------------------------------------------------
 VEHICLE GENERATIONS
--------------------------------------------------------
*/

CREATE TABLE IF NOT EXISTS vehicle_generations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    model_id UUID NOT NULL
        REFERENCES vehicle_models(id)
        ON DELETE CASCADE,

    name VARCHAR(200),

    code VARCHAR(100),

    production_from DATE,
    production_to DATE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


/*
--------------------------------------------------------
 ENGINES
--------------------------------------------------------
*/

CREATE TABLE IF NOT EXISTS engines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    code VARCHAR(100),

    name VARCHAR(200),

    fuel_type VARCHAR(40),

    displacement_cc INTEGER,

    power_kw NUMERIC(8,2),

    power_hp NUMERIC(8,2),

    production_from DATE,
    production_to DATE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


/*
--------------------------------------------------------
 VEHICLE VARIANTS
 Concrete vehicle configuration
--------------------------------------------------------
*/

CREATE TABLE IF NOT EXISTS vehicle_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    generation_id UUID NOT NULL
        REFERENCES vehicle_generations(id)
        ON DELETE CASCADE,

    engine_id UUID
        REFERENCES engines(id)
        ON DELETE SET NULL,

    body_type VARCHAR(100),

    transmission VARCHAR(100),

    drive_type VARCHAR(100),

    market VARCHAR(100),

    production_from DATE,
    production_to DATE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


/*
--------------------------------------------------------
 FITMENT
 Part → vehicle applicability
--------------------------------------------------------
*/

CREATE TABLE IF NOT EXISTS fitments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    part_id UUID NOT NULL
        REFERENCES parts(id)
        ON DELETE CASCADE,

    vehicle_variant_id UUID NOT NULL
        REFERENCES vehicle_variants(id)
        ON DELETE CASCADE,

    fitment_type VARCHAR(40) NOT NULL DEFAULT 'confirmed',

    confidence_score NUMERIC(5,2)
        NOT NULL DEFAULT 0
        CHECK (
            confidence_score >= 0
            AND confidence_score <= 100
        ),

    source_id UUID,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fitments_type_check
        CHECK (
            fitment_type IN (
                'exact',
                'confirmed',
                'possible',
                'vin_required',
                'not_confirmed'
            )
        ),

    CONSTRAINT fitments_unique
        UNIQUE (
            part_id,
            vehicle_variant_id
        )
);


/*
--------------------------------------------------------
 INDEXES
--------------------------------------------------------
*/

CREATE INDEX IF NOT EXISTS idx_parts_brand
    ON parts(brand_id);

CREATE INDEX IF NOT EXISTS idx_parts_category
    ON parts(category_id);

CREATE INDEX IF NOT EXISTS idx_parts_status
    ON parts(status);

CREATE INDEX IF NOT EXISTS idx_parts_name_normalized
    ON parts(normalized_name);

CREATE INDEX IF NOT EXISTS idx_part_numbers_normalized
    ON part_numbers(normalized_number);

CREATE INDEX IF NOT EXISTS idx_part_numbers_part
    ON part_numbers(part_id);

CREATE INDEX IF NOT EXISTS idx_part_numbers_type
    ON part_numbers(number_type);

CREATE INDEX IF NOT EXISTS idx_part_relations_source
    ON part_relations(source_part_id);

CREATE INDEX IF NOT EXISTS idx_part_relations_target
    ON part_relations(target_part_id);

CREATE INDEX IF NOT EXISTS idx_vehicle_models_make
    ON vehicle_models(make_id);

CREATE INDEX IF NOT EXISTS idx_vehicle_generations_model
    ON vehicle_generations(model_id);

CREATE INDEX IF NOT EXISTS idx_vehicle_variants_generation
    ON vehicle_variants(generation_id);

CREATE INDEX IF NOT EXISTS idx_vehicle_variants_engine
    ON vehicle_variants(engine_id);

CREATE INDEX IF NOT EXISTS idx_fitments_part
    ON fitments(part_id);

CREATE INDEX IF NOT EXISTS idx_fitments_vehicle
    ON fitments(vehicle_variant_id);


/*
--------------------------------------------------------
 UPDATED_AT FUNCTION
--------------------------------------------------------
*/

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


/*
--------------------------------------------------------
 UPDATED_AT TRIGGERS
--------------------------------------------------------
*/

DROP TRIGGER IF EXISTS brands_updated_at
ON brands;

CREATE TRIGGER brands_updated_at
BEFORE UPDATE ON brands
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


DROP TRIGGER IF EXISTS categories_updated_at
ON categories;

CREATE TRIGGER categories_updated_at
BEFORE UPDATE ON categories
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


DROP TRIGGER IF EXISTS parts_updated_at
ON parts;

CREATE TRIGGER parts_updated_at
BEFORE UPDATE ON parts
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


DROP TRIGGER IF EXISTS vehicle_makes_updated_at
ON vehicle_makes;

CREATE TRIGGER vehicle_makes_updated_at
BEFORE UPDATE ON vehicle_makes
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


DROP TRIGGER IF EXISTS vehicle_models_updated_at
ON vehicle_models;

CREATE TRIGGER vehicle_models_updated_at
BEFORE UPDATE ON vehicle_models
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


DROP TRIGGER IF EXISTS vehicle_generations_updated_at
ON vehicle_generations;

CREATE TRIGGER vehicle_generations_updated_at
BEFORE UPDATE ON vehicle_generations
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


DROP TRIGGER IF EXISTS engines_updated_at
ON engines;

CREATE TRIGGER engines_updated_at
BEFORE UPDATE ON engines
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


DROP TRIGGER IF EXISTS vehicle_variants_updated_at
ON vehicle_variants;

CREATE TRIGGER vehicle_variants_updated_at
BEFORE UPDATE ON vehicle_variants
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


/*
--------------------------------------------------------
 FINISH
--------------------------------------------------------
*/

COMMIT;