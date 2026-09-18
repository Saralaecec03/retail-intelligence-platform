-- ============================================================
-- FINAL FIX: Adds warehouse config + MCP custom tool to all 3 agents
-- Run ALL statements in a SQL worksheet (ACCOUNTADMIN role)
-- ============================================================

-- ============================================================
-- 1. PRODUCT MATCHING AGENT
-- ============================================================
CREATE OR REPLACE AGENT HACKATHON.RETAIL.PRODUCT_MATCHING_AGENT
  COMMENT = 'Product Matching Agent - multi-strategy approach for entity resolution'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    response: |-
      You are a Product Matching Agent for a retail intelligence platform.
      Your job is to help users find matching products across different retailers (Abt and Buy).

      You use a multi-strategy approach:
      1. Semantic search via embeddings (vector similarity)
      2. Fuzzy string matching (Jaro-Winkler)
      3. LLM-based verification for high-confidence confirmation

      When users ask about product matches:
      - Use the product_search tool to find relevant products
      - Use the retail_analytics tool to query match confidence and pricing data
      - Explain the confidence scores and which strategies contributed most

      When users ask about pricing:
      - Use the get_competitive_price tool to look up real-time competitive prices
      - Compare prices between retailers for matched products
      - Identify the biggest price gaps and recommend where to buy
      - Analyze pricing trends over time

      Always provide confidence scores and explain your reasoning.

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "retail_analytics"
        description: "Query structured product matching and pricing data across Abt and Buy retailers. Use for match confidence scores, price comparisons, manufacturer analysis, and matching accuracy metrics."
    - tool_spec:
        type: "cortex_search"
        name: "product_search"
        description: "Search product catalogs across retailers to find matching products by name, description, or manufacturer."
    - tool_spec:
        type: "generic"
        name: "get_competitive_price"
        description: "Look up competitive pricing for a specific product across both Abt and Buy retailers. Returns both prices, the price difference, and a recommendation on which retailer is cheaper. Use this when a user asks about a specific product's price."
        input_schema:
          type: "object"
          properties:
            product_name:
              type: "string"
              description: "The product name or keyword to search for across retailer catalogs"
          required:
            - "product_name"

  tool_resources:
    retail_analytics:
      semantic_view: "HACKATHON.RETAIL.RETAIL_INTELLIGENCE"
      execution_environment:
        type: "warehouse"
        warehouse: "HACKATHON_WH"
    product_search:
      search_service: "HACKATHON.RETAIL.PRODUCT_SEARCH_SERVICE"
      max_results: "10"
    get_competitive_price:
      type: "function"
      identifier: "HACKATHON.RETAIL.GET_COMPETITIVE_PRICE"
      execution_environment:
        type: "warehouse"
        warehouse: "HACKATHON_WH"
  $$;


-- ============================================================
-- 2. PRICE OPTIMIZATION AGENT
-- ============================================================
CREATE OR REPLACE AGENT HACKATHON.RETAIL.PRICE_OPTIMIZATION_AGENT
  COMMENT = 'Price Optimization Agent - competitive pricing analysis and recommendations'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    response: |-
      You are a Price Optimization Agent for competitive retail analysis.
      Your primary focus is helping retailers optimize their pricing strategy.

      Your capabilities:
      1. Competitive Price Analysis: Compare prices of matched products between Abt and Buy
      2. Price Gap Identification: Find products where one retailer significantly undercuts another
      3. Pricing Recommendations: Suggest optimal price points based on competitive data
      4. Trend Detection: Analyze pricing history to identify seasonal patterns or trends

      When analyzing prices:
      - Always show the price at both retailers and the percentage difference
      - Categorize products by price competitiveness (within 5%, 5-10%, >10% gap)
      - Consider manufacturer and product category when making recommendations
      - Use historical pricing data to show price movement trends
      - Use the get_competitive_price tool for quick single-product price lookups

      Provide actionable insights like:
      - "Product X is 15% cheaper at Buy.com - consider matching or undercutting"
      - "Sony products tend to have smaller price gaps (avg 3%) vs other brands"
      - "Prices for category Y have been trending down 2% monthly"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "retail_analytics"
        description: "Query structured product matching and pricing data. Use for price comparisons, gap analysis, manufacturer pricing trends, and historical price data across Abt and Buy retailers."
    - tool_spec:
        type: "cortex_search"
        name: "product_search"
        description: "Search product catalogs to find products for price analysis by name, brand, or category."
    - tool_spec:
        type: "generic"
        name: "get_competitive_price"
        description: "Look up competitive pricing for a specific product across both Abt and Buy retailers. Returns both prices and a recommendation on which retailer is cheaper. Use this for quick single-product price checks."
        input_schema:
          type: "object"
          properties:
            product_name:
              type: "string"
              description: "The product name or keyword to search for"
          required:
            - "product_name"

  tool_resources:
    retail_analytics:
      semantic_view: "HACKATHON.RETAIL.RETAIL_INTELLIGENCE"
      execution_environment:
        type: "warehouse"
        warehouse: "HACKATHON_WH"
    product_search:
      search_service: "HACKATHON.RETAIL.PRODUCT_SEARCH_SERVICE"
      max_results: "10"
    get_competitive_price:
      type: "function"
      identifier: "HACKATHON.RETAIL.GET_COMPETITIVE_PRICE"
      execution_environment:
        type: "warehouse"
        warehouse: "HACKATHON_WH"
  $$;


-- ============================================================
-- 3. MARKET INTELLIGENCE AGENT
-- ============================================================
CREATE OR REPLACE AGENT HACKATHON.RETAIL.MARKET_INTELLIGENCE_AGENT
  COMMENT = 'Market Intelligence Agent - trend detection and strategic insights'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    response: |-
      You are a Market Intelligence Agent for retail trend detection and analysis.
      You help retailers understand market dynamics, competitive positioning, and emerging trends.

      Your capabilities:
      1. Market Trend Detection: Identify price movements, category shifts, and competitive dynamics
      2. Brand Analysis: Compare how different manufacturers are positioned across retailers
      3. Match Quality Assessment: Evaluate the accuracy and coverage of product matching
      4. Strategic Insights: Provide high-level market intelligence for business decisions

      When analyzing market trends:
      - Group analysis by manufacturer/brand to show competitive positioning
      - Identify which product categories have the most price competition
      - Detect patterns in matching confidence that indicate market segments
      - Highlight products with unusual pricing patterns (potential errors or opportunities)
      - Use the get_competitive_price tool to spot-check individual product pricing

      Provide strategic-level insights:
      - Market share indicators based on product catalog coverage
      - Competitive intensity metrics by category
      - Matching accuracy metrics as data quality indicators
      - Recommendations for catalog expansion or competitive response

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "retail_analytics"
        description: "Query structured data for market intelligence: match accuracy by tier, manufacturer analysis, pricing distributions, competitive positioning metrics across Abt and Buy retailers."
    - tool_spec:
        type: "cortex_search"
        name: "product_search"
        description: "Search product catalogs for market trend analysis across retailers."
    - tool_spec:
        type: "generic"
        name: "get_competitive_price"
        description: "Look up competitive pricing for a specific product across both retailers. Use this to spot-check individual product pricing when investigating market anomalies or competitive positioning."
        input_schema:
          type: "object"
          properties:
            product_name:
              type: "string"
              description: "The product name or keyword to search for"
          required:
            - "product_name"

  tool_resources:
    retail_analytics:
      semantic_view: "HACKATHON.RETAIL.RETAIL_INTELLIGENCE"
      execution_environment:
        type: "warehouse"
        warehouse: "HACKATHON_WH"
    product_search:
      search_service: "HACKATHON.RETAIL.PRODUCT_SEARCH_SERVICE"
      max_results: "10"
    get_competitive_price:
      type: "function"
      identifier: "HACKATHON.RETAIL.GET_COMPETITIVE_PRICE"
      execution_environment:
        type: "warehouse"
        warehouse: "HACKATHON_WH"
  $$;


-- ============================================================
-- 4. VERIFY DEPLOYMENT
-- Run each DESCRIBE + SELECT pair together (select both, then Run)
-- ============================================================

-- Verify Product Matching Agent (run this pair together)
DESCRIBE AGENT HACKATHON.RETAIL.PRODUCT_MATCHING_AGENT;
SELECT 'PRODUCT_MATCHING_AGENT' AS agent_name,
       TRY_PARSE_JSON("agent_spec"):tool_resources:retail_analytics:execution_environment:warehouse::VARCHAR AS analyst_wh,
       TRY_PARSE_JSON("agent_spec"):tool_resources:get_competitive_price:identifier::VARCHAR AS mcp_tool,
       ARRAY_SIZE(TRY_PARSE_JSON("agent_spec"):tools) AS tool_count
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- Verify Price Optimization Agent (run this pair together)
DESCRIBE AGENT HACKATHON.RETAIL.PRICE_OPTIMIZATION_AGENT;
SELECT 'PRICE_OPTIMIZATION_AGENT' AS agent_name,
       TRY_PARSE_JSON("agent_spec"):tool_resources:retail_analytics:execution_environment:warehouse::VARCHAR AS analyst_wh,
       TRY_PARSE_JSON("agent_spec"):tool_resources:get_competitive_price:identifier::VARCHAR AS mcp_tool,
       ARRAY_SIZE(TRY_PARSE_JSON("agent_spec"):tools) AS tool_count
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- Verify Market Intelligence Agent (run this pair together)
DESCRIBE AGENT HACKATHON.RETAIL.MARKET_INTELLIGENCE_AGENT;
SELECT 'MARKET_INTELLIGENCE_AGENT' AS agent_name,
       TRY_PARSE_JSON("agent_spec"):tool_resources:retail_analytics:execution_environment:warehouse::VARCHAR AS analyst_wh,
       TRY_PARSE_JSON("agent_spec"):tool_resources:get_competitive_price:identifier::VARCHAR AS mcp_tool,
       ARRAY_SIZE(TRY_PARSE_JSON("agent_spec"):tools) AS tool_count
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));


-- ============================================================
-- 5. TEST ALL THREE AGENTS
-- ============================================================

-- Test Product Matching Agent (uses Analyst + Search)
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HACKATHON.RETAIL.PRODUCT_MATCHING_AGENT',
    '{"messages":[{"role":"user","content":[{"type":"text","text":"How many high confidence product matches do we have? Show the top 5."}]}]}'
  )
):content AS product_matching_test;

-- Test Price Optimization Agent (uses Analyst)
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HACKATHON.RETAIL.PRICE_OPTIMIZATION_AGENT',
    '{"messages":[{"role":"user","content":[{"type":"text","text":"Which 5 products have the biggest price gap between Abt and Buy?"}]}]}'
  )
):content AS price_optimization_test;

-- Test Market Intelligence Agent (uses Analyst)
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HACKATHON.RETAIL.MARKET_INTELLIGENCE_AGENT',
    '{"messages":[{"role":"user","content":[{"type":"text","text":"Summarize matching accuracy by tier and which manufacturers have the most competitive pricing."}]}]}'
  )
):content AS market_intelligence_test;

-- Test MCP custom tool directly (should work for all agents)
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HACKATHON.RETAIL.PRODUCT_MATCHING_AGENT',
    '{"messages":[{"role":"user","content":[{"type":"text","text":"What is the competitive price for Sony DSLR cameras?"}]}]}'
  )
):content AS mcp_tool_test;
