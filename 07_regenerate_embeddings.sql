-- =============================================================
-- 07_regenerate_embeddings.sql — Regenerate VECTOR embeddings
-- Run AFTER loading data into ABT and BUY tables
-- =============================================================

USE DATABASE HACKATHON;
USE SCHEMA RETAIL;
USE WAREHOUSE HACKATHON_WH;

-- Regenerate ABT embeddings
INSERT INTO ABT_EMBEDDINGS
SELECT
    ID, NAME, DESCRIPTION, PRICE,
    SNOWFLAKE.CORTEX.EMBED_TEXT_1024('snowflake-arctic-embed-m-v1.5',
        NAME || ' ' || COALESCE(DESCRIPTION, '')) AS EMBEDDING
FROM ABT;

-- Regenerate BUY embeddings
INSERT INTO BUY_EMBEDDINGS
SELECT
    ID, NAME, DESCRIPTION, MANUFACTURER, PRICE,
    SNOWFLAKE.CORTEX.EMBED_TEXT_1024('snowflake-arctic-embed-m-v1.5',
        NAME || ' ' || COALESCE(DESCRIPTION, '')) AS EMBEDDING
FROM BUY;
