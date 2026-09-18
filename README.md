Retail Intelligence Platform
AI-Powered Entity Resolution Pipeline for Cross-Retailer Product Matching & Competitive Pricing

Problem Statement
Design an AI-powered entity resolution pipeline that automatically matches products across different retailers, enabling dynamic competitive pricing strategies and comprehensive price comparisons.

Solution Overview
A multi-strategy product matching pipeline built entirely on Snowflake, combining vector embeddings, fuzzy string matching, and LLM verification to achieve 90.6% precision on high-confidence matches across 1,081 product pairs.

Snowflake Features Implemented
Feature	Usage
Cortex Embeddings (snowflake-arctic-embed-m-v1.5)	Vector similarity matching
Cortex LLM (Claude)	Match verification with reasoning
Cortex Agents (×3)	Product matching, price optimization, market intelligence
Cortex Analyst	Text-to-SQL via semantic view
Cortex Search Service	Semantic product catalog search
Semantic View	RETAIL_INTELLIGENCE with metrics, dimensions, verified queries
MCP Custom Tool	GET_COMPETITIVE_PRICE UDF attached to all agents
Streamlit Dashboard	4-page interactive app with agent chat
Repository Structure
~/retail-intelligence-platform/
├── README.md
├── ARCHITECTURE.md
├── cortex_project/
│ ├── cortex-project.yaml
│ ├── product_matching_agent.agent.yaml
│ ├── price_optimization_agent.agent.yaml
│ ├── market_intelligence_agent.agent.yaml
│ └── retail_intelligence.sv.yaml
├── streamlit_app/
│ └── streamlit_app.py  
├── sql/
│ └── deploy_agents.sql  
├── monitoring/
  └── monitor_agents.sql
 
Quick Start
Run SQL scripts in order (sql/01_setup_schema.sql through sql/10_deploy_agents.sql)
Deploy the semantic view from cortex_project/retail_intelligence.sv.yaml
Deploy the Streamlit app from streamlit_app/
Test agents via the dashboard Agent Chat page or DATA_AGENT_RUN
Matching Accuracy
Tier	Predictions	True Positives	Precision
HIGH (>=0.85)	800	725	90.63%
MEDIUM (>=0.70)	279	189	67.74%
LOW (<0.70)	2	2	100%
Dataset
Abt Products: 1,081 items (names, descriptions, prices)

Buy Products: 1,092 items (names, descriptions, prices, manufacturers)

Ground Truth: 1,097 validated product pair mappings

Pricing History: 10,932 historical price records