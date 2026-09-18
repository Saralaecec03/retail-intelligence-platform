-- ============================================================
-- AGENT PERFORMANCE MONITORING DASHBOARD
-- Run in a SQL worksheet after executing fix_and_test_agents.sql
-- ============================================================

-- ============================================================
-- 1. Create a reusable monitoring view
-- ============================================================
CREATE OR REPLACE VIEW HACKATHON.RETAIL.V_AGENT_PERFORMANCE AS
WITH agent_invocations AS (
    SELECT 
        AGENT_NAME,
        REQUEST_ID,
        USER_NAME,
        start_time,
        end_time,
        TIMESTAMPDIFF('millisecond', start_time, end_time) AS latency_ms,
        ROUND(TIMESTAMPDIFF('millisecond', start_time, end_time) / 1000.0, 1) AS latency_sec,
        TOKENS AS total_tokens,
        ROUND(TOKEN_CREDITS, 6) AS token_credits,
        METADATA:role_name::VARCHAR AS role_name,
        METADATA:inference_region::VARCHAR AS inference_region,
        f.value[REQUEST_ID] AS req_detail
    FROM SNOWFLAKE.ACCOUNT_USAGE.SNOWFLAKE_INTELLIGENCE_USAGE_HISTORY,
         LATERAL FLATTEN(input => TOKENS_GRANULAR) f
    WHERE AGENT_DATABASE_NAME = 'HACKATHON'
      AND AGENT_SCHEMA_NAME = 'RETAIL'
      AND AGENT_NAME IS NOT NULL
)
SELECT 
    AGENT_NAME,
    REQUEST_ID,
    USER_NAME,
    role_name,
    start_time,
    end_time,
    latency_ms,
    latency_sec,
    total_tokens,
    token_credits,
    inference_region,
    OBJECT_KEYS(req_detail:cortex_agents)[0]::VARCHAR AS model_used,
    req_detail:cortex_agents[model_used]:input::INT AS input_tokens,
    req_detail:cortex_agents[model_used]:output::INT AS output_tokens,
    req_detail:cortex_agents[model_used]:cache_read_input::INT AS cache_read_tokens,
    req_detail:cortex_agents[model_used]:cache_write_input::INT AS cache_write_tokens,
    CASE WHEN latency_sec > 0 THEN ROUND(output_tokens / latency_sec, 1) ELSE 0 END AS output_tokens_per_sec
FROM agent_invocations;


-- ============================================================
-- 2. Agent performance summary (run after test queries)
-- ============================================================
SELECT 
    AGENT_NAME,
    COUNT(*) AS total_calls,
    ROUND(AVG(latency_sec), 1) AS avg_latency_sec,
    ROUND(MIN(latency_sec), 1) AS min_latency_sec,
    ROUND(MAX(latency_sec), 1) AS max_latency_sec,
    ROUND(AVG(total_tokens), 0) AS avg_tokens,
    ROUND(SUM(token_credits), 6) AS total_credits,
    ROUND(AVG(output_tokens_per_sec), 1) AS avg_output_tps,
    model_used
FROM HACKATHON.RETAIL.V_AGENT_PERFORMANCE
GROUP BY AGENT_NAME, model_used
ORDER BY total_calls DESC;


-- ============================================================
-- 3. Per-call detail log
-- ============================================================
SELECT 
    AGENT_NAME,
    REQUEST_ID,
    start_time,
    latency_sec,
    model_used,
    input_tokens,
    output_tokens,
    cache_read_tokens,
    cache_write_tokens,
    total_tokens,
    token_credits,
    output_tokens_per_sec
FROM HACKATHON.RETAIL.V_AGENT_PERFORMANCE
ORDER BY start_time DESC;


-- ============================================================
-- 4. Agent creation audit trail (from query history)
-- ============================================================
SELECT 
    TO_CHAR(start_time, 'YYYY-MM-DD HH24:MI:SS') AS time,
    CASE
        WHEN query_text ILIKE '%PRODUCT_MATCHING%' THEN 'Product Matching'
        WHEN query_text ILIKE '%PRICE_OPTIM%' THEN 'Price Optimization'
        WHEN query_text ILIKE '%MARKET_INTEL%' THEN 'Market Intelligence'
        ELSE 'Unknown'
    END AS agent,
    execution_status AS status,
    total_elapsed_time AS elapsed_ms,
    COALESCE(SUBSTR(error_message, 1, 80), 'OK') AS result
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE query_text ILIKE '%CREATE%AGENT%HACKATHON%'
  AND start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;


-- ============================================================
-- 5. Failed invocations analysis (sandbox vs worksheet)
-- ============================================================
SELECT 
    SUBSTR(error_message, 1, 60) AS error_category,
    COUNT(*) AS occurrences,
    MIN(start_time) AS first_seen,
    MAX(start_time) AS last_seen
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE query_text ILIKE '%DATA_AGENT_RUN%'
  AND execution_status = 'FAIL'
  AND start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY 1
ORDER BY occurrences DESC;


-- ============================================================
-- 6. Agent observability events (traces + spans)
-- Requires MONITOR privilege on the agent
-- ============================================================

-- Product Matching Agent traces
SELECT *
FROM TABLE(SNOWFLAKE.LOCAL.GET_AI_OBSERVABILITY_EVENTS(
    'HACKATHON', 'RETAIL', 'PRODUCT_MATCHING_AGENT', 'CORTEX AGENT'
))
ORDER BY START_TIMESTAMP DESC
LIMIT 50;

-- Price Optimization Agent traces
SELECT *
FROM TABLE(SNOWFLAKE.LOCAL.GET_AI_OBSERVABILITY_EVENTS(
    'HACKATHON', 'RETAIL', 'PRICE_OPTIMIZATION_AGENT', 'CORTEX AGENT'
))
ORDER BY START_TIMESTAMP DESC
LIMIT 50;

-- Market Intelligence Agent traces
SELECT *
FROM TABLE(SNOWFLAKE.LOCAL.GET_AI_OBSERVABILITY_EVENTS(
    'HACKATHON', 'RETAIL', 'MARKET_INTELLIGENCE_AGENT', 'CORTEX AGENT'
))
ORDER BY START_TIMESTAMP DESC
LIMIT 50;
