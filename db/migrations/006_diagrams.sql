CREATE TABLE IF NOT EXISTS diagrams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name TEXT NOT NULL,

    part_id UUID REFERENCES parts(id) ON DELETE SET NULL,

    media_asset_id UUID REFERENCES media_assets(id) ON DELETE SET NULL,

    source_id UUID REFERENCES data_sources(id) ON DELETE SET NULL,

    vehicle_make_id UUID REFERENCES vehicle_makes(id) ON DELETE SET NULL,
    vehicle_model_id UUID REFERENCES vehicle_models(id) ON DELETE SET NULL,
    vehicle_generation_id UUID REFERENCES vehicle_generations(id) ON DELETE SET NULL,

    diagram_type VARCHAR(50) NOT NULL DEFAULT 'exploded',

    description TEXT,

    version VARCHAR(100),

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_diagrams_part
    ON diagrams(part_id);

CREATE INDEX IF NOT EXISTS idx_diagrams_vehicle
    ON diagrams(
        vehicle_make_id,
        vehicle_model_id,
        vehicle_generation_id
    );

CREATE INDEX IF NOT EXISTS idx_diagrams_active
    ON diagrams(is_active);

CREATE OR REPLACE FUNCTION set_diagrams_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_diagrams_updated_at
ON diagrams;

CREATE TRIGGER trg_diagrams_updated_at
BEFORE UPDATE ON diagrams
FOR EACH ROW
EXECUTE FUNCTION set_diagrams_updated_at();


CREATE TABLE IF NOT EXISTS diagram_positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    diagram_id UUID NOT NULL
        REFERENCES diagrams(id)
        ON DELETE CASCADE,

    position_number VARCHAR(50) NOT NULL,

    label TEXT,

    x NUMERIC(10,6) NOT NULL,
    y NUMERIC(10,6) NOT NULL,

    width NUMERIC(10,6),
    height NUMERIC(10,6),

    shape VARCHAR(30) NOT NULL DEFAULT 'point',

    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(diagram_id, position_number)
);

CREATE INDEX IF NOT EXISTS idx_diagram_positions_diagram
    ON diagram_positions(diagram_id);


CREATE TABLE IF NOT EXISTS diagram_position_parts (
    diagram_position_id UUID NOT NULL
        REFERENCES diagram_positions(id)
        ON DELETE CASCADE,

    part_id UUID NOT NULL
        REFERENCES parts(id)
        ON DELETE CASCADE,

    relation_type VARCHAR(30) NOT NULL DEFAULT 'contains',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY(diagram_position_id, part_id)
);

CREATE INDEX IF NOT EXISTS idx_diagram_position_parts_part
    ON diagram_position_parts(part_id);