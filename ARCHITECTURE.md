Retail Intelligence Platform - Architecture Documentation
1. Solution Overview
An AI-powered entity resolution pipeline that matches products across two retailers (Abt and Buy), enabling competitive pricing strategies and price comparisons. Built entirely on Snowflake using Cortex AI functions, Cortex Agents, Semantic Views, and a Streamlit dashboard.

Key Metrics: 1,081 products matched | 90.6% precision (HIGH tier) | 3 AI agents | 1 semantic view | 1 MCP custom tool

2. Architecture Diagram
┌─────────────────────────────────────────────────────────────────────┐
│                     SNOWFLAKE ACCOUNT (HACKATHON)                   │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                   HACKATHON.RETAIL Schema                     │  │
│  │                                                               │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌──────────────────────┐  │  │
│  │  │  ABT (1081)  │  │ BUY (1092)  │  │ ABT_BUY_PERFECT_     │  │  │
│  │  │  Products    │  │  Products   │  │ MAPPING (1097 pairs) │  │  │
│  │  └──────┬───────┘  └──────┬──────┘  │ (Ground Truth)       │  │  │
│  │         │                 │         └──────────────────────┘  │  │
│  │         ▼                 ▼                                   │  │
│  │  ┌──────────────────────────────────────────┐                 │  │
│  │  │     MULTI-STRATEGY MATCHING PIPELINE      │                 │  │
│  │  │                                          │                 │  │
│  │  │  1. VECTOR MATCHING (Cosine Similarity)  │                 │  │
│  │  │     snowflake-arctic-embed-m-v1.5        │                 │  │
│  │  │     ABT_EMBEDDINGS ←→ BUY_EMBEDDINGS     │                 │  │
│  │  │              ↓                           │                 │  │
│  │  │  2. FUZZY MATCHING (Jaro-Winkler)        │                 │  │
│  │  │     String similarity on product names   │                 │  │
│  │  │              ↓                           │                 │  │
│  │  │  3. LLM VERIFICATION (Claude)            │                 │  │
│  │  │     Confidence scoring + reasoning       │                 │  │
│  │  └──────────────┬───────────────────────────┘                 │  │
│  │                 ▼                                             │  │
│  │  ┌──────────────────────────┐  ┌──────────────────────┐      │  │
│  │  │ PRODUCT_MATCHES_FINAL    │  │ PRICING_HISTORY      │      │  │
│  │  │ (1081 matched pairs)     │  │ (10,932 records)     │      │  │
│  │  │ Combined confidence,     │  │ Time-series pricing  │      │  │
│  │  │ tier, price diff, LLM    │  │ across retailers     │      │  │
│  │  │ reasoning                │  └───────────┬──────────┘      │  │
│  │  └──────────┬───────────────┘              │                 │  │
│  │             │              ┌────────────────┘                 │  │
│  │             ▼              ▼                                  │  │
│  │  ┌──────────────────────────────────┐                        │  │
│  │  │   SEMANTIC VIEW                  │                        │  │
│  │  │   RETAIL_INTELLIGENCE            │                        │  │
│  │  │   • 2 tables, 4 metrics          │                        │  │
│  │  │   • 6 dimensions, 2 facts        │                        │  │
│  │  │   • 4 verified queries           │                        │  │
│  │  │   • 1 relationship               │                        │  │
│  │  └──────────┬───────────────────────┘                        │  │
│  │             │                                                │  │
│  │             ▼                                                │  │
│  │  ┌──────────────────────────────────────────────────────┐    │  │
│  │  │              CORTEX AGENTS (×3)                       │    │  │
│  │  │                                                      │    │  │
│  │  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │    │  │
│  │  │  │  PRODUCT     │ │  PRICE       │ │  MARKET      │  │    │  │
│  │  │  │  MATCHING    │ │  OPTIMIZATION│ │  INTELLIGENCE│  │    │  │
│  │  │  │  AGENT       │ │  AGENT       │ │  AGENT       │  │    │  │
│  │  │  └──────────────┘ └──────────────┘ └──────────────┘  │    │  │
│  │  │                                                      │    │  │
│  │  │  Tools per agent:                                    │    │  │
│  │  │  • Cortex Analyst (text-to-SQL via semantic view)    │    │  │
│  │  │  • Cortex Search (PRODUCT_SEARCH_SERVICE)            │    │  │
│  │  │  • MCP Custom Tool (GET_COMPETITIVE_PRICE UDF)       │    │  │
│  │  └──────────────────────────┬───────────────────────────┘    │  │
│  │                             │                                │  │
│  │                             ▼                                │  │
│  │  ┌──────────────────────────────────────────────────────┐    │  │
│  │  │           STREAMLIT DASHBOARD (4 pages)              │    │  │
│  │  │                                                      │    │  │
│  │  │  Overview │ Product Matches │ Price Analysis │ Chat  │    │  │
│  │  │  KPIs     │ Explorer+Search │ Gap Analysis   │ Agent │    │  │
│  │  │  Charts   │ LLM Reasoning   │ Manufacturer   │ UI    │    │  │
│  │  └──────────────────────────────────────────────────────┘    │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
3. Snowflake Features Used
Feature	Implementation	Object
Cortex Embeddings	snowflake-arctic-embed-m-v1.5 for vector similarity matching	ABT_EMBEDDINGS, BUY_EMBEDDINGS
Cortex LLM	Claude for match verification with reasoning	MATCHES_LLM_VERIFIED
Cortex Agents	3 agents with Analyst + Search + MCP tools	PRODUCT_MATCHING_AGENT, PRICE_OPTIMIZATION_AGENT, MARKET_INTELLIGENCE_AGENT
Cortex Analyst	Text-to-SQL via semantic view	RETAIL_INTELLIGENCE semantic view
Cortex Search	Semantic product catalog search	PRODUCT_SEARCH_SERVICE
Semantic View	2 tables, 4 metrics, 6 dimensions, 4 verified queries	RETAIL_INTELLIGENCE
MCP Integration	Custom UDF as agent tool	GET_COMPETITIVE_PRICE(VARCHAR)
Streamlit	4-page interactive dashboard with agent chat	HACKATHON.RETAIL.UNTITLED
4. Data Pipeline
Stage 1: Data Ingestion
ABT: 1,081 products (names, descriptions, prices)
BUY: 1,092 products (names, descriptions, prices, manufacturers)
Ground Truth: 1,097 validated product pairs for accuracy evaluation
Stage 2: Embedding Generation
Model: snowflake-arctic-embed-m-v1.5
Generated 768-dimensional vectors for all products in both catalogs
Stage 3: Multi-Strategy Matching
Vector Matching → MATCHES_VECTOR (3,243 candidate pairs, cosine similarity)
Fuzzy Matching → MATCHES_FUZZY (3,243 pairs, Jaro-Winkler distance)
LLM Verification → MATCHES_LLM_VERIFIED (1,081 verified with reasoning)
Stage 4: Score Combination
Combined confidence = weighted blend of vector, fuzzy, and LLM scores
Tier classification: HIGH (>=0.85), MEDIUM (>=0.70), LOW (<0.70)
Output: PRODUCT_MATCHES_FINAL (1,081 matched pairs)
Stage 5: Accuracy Validation
Evaluated against ABT_BUY_PERFECT_MAPPING ground truth:

Tier	Predictions	True Positives	Precision
HIGH	800	725	90.63%
MEDIUM	279	189	67.74%
LOW	2	2	100%
5. Agent Architecture
Each agent is configured with:

Orchestration: auto (Snowflake selects optimal model)
Cortex Analyst tool (cortex_analyst_text_to_sql): Converts natural language to SQL queries against the RETAIL_INTELLIGENCE semantic view
Cortex Search tool (cortex_search): Semantic search across product catalogs via PRODUCT_SEARCH_SERVICE
MCP Custom tool (generic): GET_COMPETITIVE_PRICE UDF for real-time single-product price lookups
Agent	Purpose	Example Queries
Product Matching	Find and verify cross-retailer product matches	"Top 10 highest confidence matches", "Find Canon product matches"
Price Optimization	Competitive pricing analysis and recommendations	"Biggest price gaps", "Which products should Abt reprice?"
Market Intelligence	Trend detection and strategic insights	"Market overview by brand", "Matching accuracy by tier"
6. Dashboard Pages
Overview: KPI metrics, confidence tier distribution, strategy scores, accuracy vs ground truth, top brands
Product Matches: Searchable explorer with vector/fuzzy/LLM scores, LLM reasoning viewer
Price Analysis: Price gap analysis by manufacturer, cheaper retailer comparison, biggest gaps table
Agent Chat: Interactive chat with all 3 agents, suggestion chips, per-agent conversation history