/*
========================================================
 AUTOPARTS HUB
 Migration 004
 Search intelligence and lost demand
========================================================
*/

BEGIN;


/*
--------------------------------------------------------
 SEARCH EVENTS
--------------------------------------------------------
*/

CREATE TABLE IF NOT EXISTS search_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    session_id VARCHAR(200),

    user_id UUID,

    query TEXT NOT NULL,

    normalized_query TEXT,

    query_type VARCHAR(40),

    vehicle_id UUID,

    results_count INTEGER NOT NULL DEFAULT 0,

    selected_part_id UUID,

    response_time_ms INTEGER,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


/*
--------------------------------------------------------
 ZERO RESULT EVENTS
--------------------------------------------------------
*/

CREATE TABLE IF NOT EXISTS zero_result_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    search_event_id UUID
        REFERENCES search_events(id)
        ON DELETE CASCADE,

    query TEXT NOT NULL,

    normalized_query TEXT,

    vehicle_id UUID,

    category_id UUID,

    session_id VARCHAR(200),

    user_id UUID,

    region VARCHAR(200),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


/*
--------------------------------------------------------
 INDEXES
--------------------------------------------------------
*/

CREATE INDEX IF NOT EXISTS idx_search_events_created
    ON search_events(created_at);

CREATE INDEX IF NOT EXISTS idx_search_events_query
    ON search_events(normalized_query);

CREATE INDEX IF NOT EXISTS idx_search_events_vehicle
    ON search_events(vehicle_id);

CREATE INDEX IF NOT EXISTS idx_zero_results_created
    ON zero_result_events(created_at);

CREATE INDEX IF NOT EXISTS idx_zero_results_query
    ON zero_result_events(normalized_query);

CREATE INDEX IF NOT EXISTS idx_zero_results_vehicle
    ON zero_result_events(vehicle_id);


/*
--------------------------------------------------------
 FINISH
--------------------------------------------------------
*/

COMMIT;