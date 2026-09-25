# Retail Intelligence Platform

AI-powered entity resolution platform comparing products across Abt and Buy retailers using Cortex Agents, Semantic Views, and Cortex Search.

## Project Structure

```
retail_intelligence_project/
├── README.md
├── app/                                          # Streamlit app files
│   ├── streamlit_app.py                          # Main app (605 lines)
│   ├── snowflake.yml                             # Deployment config
│   ├── pyproject.toml                            # Python dependencies
│   └── .streamlit/
│       └── config.toml                           # Theme config
├── cortex_project/                               # Cortex Project YAML definitions
│   ├── cortex-project.yaml                       # Project manifest (links all artifacts)
│   ├── retail_intelligence.sv.yaml               # Semantic View definition (with verified queries)
│   ├── product_matching_agent.agent.yaml         # Product Matching Agent spec
│   ├── price_optimization_agent.agent.yaml       # Price Optimization Agent spec
│   └── market_intelligence_agent.agent.yaml      # Market Intelligence Agent spec
├── sql/                                          # Run these in order
│   ├── 00_export_data.sql                        # [CURRENT ACCOUNT] Export table data
│   ├── 01_setup.sql                              # Create warehouses, DB, schema, tables
│   ├── 02_views_and_function.sql                 # Create views + GET_COMPETITIVE_PRICE function
│   ├── 03_semantic_view.yaml                     # Semantic View YAML (alternate, for Snowsight UI)
│   ├── 04_cortex_search.sql                      # Create Cortex Search Service
│   ├── 05_agents.sql                             # Create all 3 Cortex Agents
│   ├── 06_load_data.sql                          # Load exported data into new account
│   └── 07_regenerate_embeddings.sql              # Regenerate VECTOR embeddings
└── data/                                         # Put downloaded Parquet files here
```

## Setup on a New Snowflake Account

### Before your current account expires

1. Run `sql/00_export_data.sql` in your current account
2. Download the exported files from the stage:
   ```
   -- In Snowsight, or via SnowSQL:
   GET @HACKATHON.RETAIL.EXPORT_STAGE file:///path/to/retail_intelligence_project/data/
   ```

### In the new account

Run the SQL scripts in order:

| Step | File | What it does |
|------|------|-------------|
| 1 | `01_setup.sql` | Creates warehouses, database, schema, and all 10 tables |
| 2 | `06_load_data.sql` | Uploads and loads your exported Parquet data |
| 3 | `07_regenerate_embeddings.sql` | Regenerates VECTOR embeddings for ABT and BUY |
| 4 | `02_views_and_function.sql` | Creates 4 views + the GET_COMPETITIVE_PRICE function |
| 5 | `04_cortex_search.sql` | Creates the Cortex Search Service |
| 6 | `03_semantic_view.yaml` | Create Semantic View via Snowsight UI (Data > + Semantic View, paste the YAML) |
| 7 | `05_agents.sql` | Creates all 3 Cortex Agents |
| 8 | Deploy Streamlit app | Copy `app/` files into a new Workspace |

### Deploying the Streamlit App

1. Go to **Projects > Workspaces** in Snowsight
2. Create a new Workspace
3. Upload or create these files in the workspace:
   - `streamlit_app.py` (from `app/`)
   - `snowflake.yml` (from `app/`)
   - `pyproject.toml` (from `app/`)
   - `.streamlit/config.toml` (from `app/`)
4. Run the app

### Alternative: Deploy via Cortex Project

Instead of running `05_agents.sql` and creating the semantic view manually, you can use the `cortex_project/` folder which contains the native Cortex Project YAML definitions:

1. Upload the `cortex_project/` folder to your new workspace
2. The `cortex-project.yaml` manifest links all artifacts:
   - `retail_intelligence.sv.yaml` — Semantic View (includes verified queries)
   - `product_matching_agent.agent.yaml` — Product Matching Agent
   - `price_optimization_agent.agent.yaml` — Price Optimization Agent
   - `market_intelligence_agent.agent.yaml` — Market Intelligence Agent
3. Deploy via the Snowsight UI or CLI

The `cortex_project/` YAMLs are the source-of-truth definitions. The `sql/05_agents.sql` and `sql/03_semantic_view.yaml` are standalone equivalents if you prefer running SQL directly.

## What's Inside

- **10 tables** — source data (ABT, BUY), ground truth, embeddings, intermediate matches, final results, pricing history
- **4 views** — competitive intelligence, matching metrics, pricing dashboard, project summary
- **1 semantic view** — RETAIL_INTELLIGENCE (powers Cortex Analyst)
- **1 Cortex Search Service** — PRODUCT_SEARCH_SERVICE (product catalog search)
- **1 custom function** — GET_COMPETITIVE_PRICE (MCP tool for agents)
- **3 Cortex Agents** — Product Matching, Price Optimization, Market Intelligence
- **1 Streamlit app** — Dashboard + Agent chat UI
