-- =============================================================
-- 05_agents.sql — All 3 Cortex Agents
-- =============================================================

USE DATABASE HACKATHON;
USE SCHEMA RETAIL;

-- -----------------------------------------------
-- Agent 1: Product Matching Agent
-- -----------------------------------------------
CREATE OR REPLACE AGENT PRODUCT_MATCHING_AGENT
  COMMENT = 'Product Matching Agent - multi-strategy approach for entity resolution'
  AGENT_SPEC = $$
{
  "models": {"orchestration": "auto"},
  "instructions": {
    "response": "You are a Product Matching Agent for a retail intelligence platform.\nYour job is to help users find matching products across different retailers (Abt and Buy).\n\nYou use a multi-strategy approach:\n1. Semantic search via embeddings (vector similarity)\n2. Fuzzy string matching (Jaro-Winkler)\n3. LLM-based verification for high-confidence confirmation\n\nWhen users ask about product matches:\n- Use the product_search tool to find relevant products\n- Use the retail_analytics tool to query match confidence and pricing data\n- Explain the confidence scores and which strategies contributed most\n\nWhen users ask about pricing:\n- Use the get_competitive_price tool to look up real-time competitive prices\n- Compare prices between retailers for matched products\n- Identify the biggest price gaps and recommend where to buy\n- Analyze pricing trends over time\n\nAlways provide confidence scores and explain your reasoning.\n"
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "retail_analytics",
        "description": "Query structured product matching and pricing data across Abt and Buy retailers."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "product_search",
        "description": "Search product catalogs across retailers to find matching products by name, description, or manufacturer."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "get_competitive_price",
        "description": "Look up competitive pricing for a specific product across both Abt and Buy retailers.",
        "input_schema": {
          "type": "object",
          "properties": {
            "product_name": {
              "type": "string",
              "description": "The product name or keyword to search for"
            }
          },
          "required": ["product_name"]
        }
      }
    }
  ],
  "tool_resources": {
    "retail_analytics": {
      "semantic_view": "HACKATHON.RETAIL.RETAIL_INTELLIGENCE",
      "execution_environment": {"type": "warehouse", "warehouse": "COMPUTE_WH"}
    },
    "product_search": {
      "search_service": "HACKATHON.RETAIL.PRODUCT_SEARCH_SERVICE",
      "max_results": "10"
    },
    "get_competitive_price": {
      "type": "function",
      "identifier": "HACKATHON.RETAIL.GET_COMPETITIVE_PRICE",
      "execution_environment": {"type": "warehouse", "warehouse": "COMPUTE_WH"}
    }
  }
}
$$;


-- -----------------------------------------------
-- Agent 2: Price Optimization Agent
-- -----------------------------------------------
CREATE OR REPLACE AGENT PRICE_OPTIMIZATION_AGENT
  COMMENT = 'Price Optimization Agent - competitive pricing analysis and recommendations'
  AGENT_SPEC = $$
{
  "models": {"orchestration": "auto"},
  "instructions": {
    "response": "You are a Price Optimization Agent for competitive retail analysis.\nYour primary focus is helping retailers optimize their pricing strategy.\n\nYour capabilities:\n1. Competitive Price Analysis: Compare prices of matched products between Abt and Buy\n2. Price Gap Identification: Find products where one retailer significantly undercuts another\n3. Pricing Recommendations: Suggest optimal price points based on competitive data\n4. Trend Detection: Analyze pricing history to identify seasonal patterns or trends\n\nWhen analyzing prices:\n- Always show the price at both retailers and the percentage difference\n- Categorize products by price competitiveness (within 5%, 5-10%, >10% gap)\n- Consider manufacturer and product category when making recommendations\n- Use historical pricing data to show price movement trends\n- Use the get_competitive_price tool for quick single-product price lookups\n\nProvide actionable insights like:\n- \"Product X is 15% cheaper at Buy.com - consider matching or undercutting\"\n- \"Sony products tend to have smaller price gaps (avg 3%) vs other brands\"\n- \"Prices for category Y have been trending down 2% monthly\""
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "retail_analytics",
        "description": "Query structured product matching and pricing data for price analysis."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "product_search",
        "description": "Search product catalogs to find products for price analysis."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "get_competitive_price",
        "description": "Look up competitive pricing for a specific product across both retailers.",
        "input_schema": {
          "type": "object",
          "properties": {
            "product_name": {
              "type": "string",
              "description": "The product name or keyword to search for"
            }
          },
          "required": ["product_name"]
        }
      }
    }
  ],
  "tool_resources": {
    "retail_analytics": {
      "semantic_view": "HACKATHON.RETAIL.RETAIL_INTELLIGENCE",
      "execution_environment": {"type": "warehouse", "warehouse": "HACKATHON_WH"}
    },
    "product_search": {
      "search_service": "HACKATHON.RETAIL.PRODUCT_SEARCH_SERVICE",
      "max_results": "10"
    },
    "get_competitive_price": {
      "type": "function",
      "identifier": "HACKATHON.RETAIL.GET_COMPETITIVE_PRICE",
      "execution_environment": {"type": "warehouse", "warehouse": "HACKATHON_WH"}
    }
  }
}
$$;


-- -----------------------------------------------
-- Agent 3: Market Intelligence Agent
-- -----------------------------------------------
CREATE OR REPLACE AGENT MARKET_INTELLIGENCE_AGENT
  COMMENT = 'Market Intelligence Agent - trend detection and strategic insights'
  AGENT_SPEC = $$
{
  "models": {"orchestration": "auto"},
  "instructions": {
    "response": "You are a Market Intelligence Agent for retail trend detection and analysis.\nYou help retailers understand market dynamics, competitive positioning, and emerging trends.\n\nYour capabilities:\n1. Market Trend Detection: Identify price movements, category shifts, and competitive dynamics\n2. Brand Analysis: Compare how different manufacturers are positioned across retailers\n3. Match Quality Assessment: Evaluate the accuracy and coverage of product matching\n4. Strategic Insights: Provide high-level market intelligence for business decisions\n\nWhen analyzing market trends:\n- Group analysis by manufacturer/brand to show competitive positioning\n- Identify which product categories have the most price competition\n- Detect patterns in matching confidence that indicate market segments\n- Highlight products with unusual pricing patterns (potential errors or opportunities)\n- Use the get_competitive_price tool to spot-check individual product pricing\n\nProvide strategic-level insights:\n- Market share indicators based on product catalog coverage\n- Competitive intensity metrics by category\n- Matching accuracy metrics as data quality indicators\n- Recommendations for catalog expansion or competitive response"
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "retail_analytics",
        "description": "Query structured data for market intelligence and competitive positioning metrics."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "product_search",
        "description": "Search product catalogs for market trend analysis across retailers."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "get_competitive_price",
        "description": "Look up competitive pricing for a specific product across both retailers.",
        "input_schema": {
          "type": "object",
          "properties": {
            "product_name": {
              "type": "string",
              "description": "The product name or keyword to search for"
            }
          },
          "required": ["product_name"]
        }
      }
    }
  ],
  "tool_resources": {
    "retail_analytics": {
      "semantic_view": "HACKATHON.RETAIL.RETAIL_INTELLIGENCE",
      "execution_environment": {"type": "warehouse", "warehouse": "HACKATHON_WH"}
    },
    "product_search": {
      "search_service": "HACKATHON.RETAIL.PRODUCT_SEARCH_SERVICE",
      "max_results": "10"
    },
    "get_competitive_price": {
      "type": "function",
      "identifier": "HACKATHON.RETAIL.GET_COMPETITIVE_PRICE",
      "execution_environment": {"type": "warehouse", "warehouse": "HACKATHON_WH"}
    }
  }
}
$$;
