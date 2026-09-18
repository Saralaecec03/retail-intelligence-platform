import os
import json
import streamlit as st

st.set_page_config(
    page_title="Retail Intelligence Platform",
    page_icon=":material/storefront:",
    layout="wide",
)

# --- Custom theme: Light Snowflake + Coral accent ---
st.markdown("""
<style>
    /* Sidebar */
    section[data-testid="stSidebar"] {
        background: linear-gradient(180deg, #FFFFFF 0%, #F0F5FA 100%);
        border-right: 2px solid #E2E8F0;
    }
    section[data-testid="stSidebar"] .stSubheader {
        color: #29B5E8 !important;
    }
    section[data-testid="stSidebar"] .stCaption p {
        color: #6B7280 !important;
    }
    section[data-testid="stSidebar"] .stDivider {
        border-color: #E2E8F0 !important;
    }

    /* Page titles */
    h1 {
        color: #1F2937 !important;
        font-weight: 700 !important;
        letter-spacing: -0.02em;
    }
    h2, h3 {
        color: #374151 !important;
    }

    /* KPI metric cards */
    div[data-testid="stMetric"] {
        background: #FFFFFF;
        border: 1px solid #E5E7EB;
        border-left: 4px solid #29B5E8;
        border-radius: 10px;
        padding: 14px 18px;
        box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
    }
    div[data-testid="stMetric"] label {
        color: #6B7280 !important;
        font-weight: 600 !important;
        text-transform: uppercase;
        font-size: 0.72rem !important;
        letter-spacing: 0.05em;
    }
    div[data-testid="stMetric"] div[data-testid="stMetricValue"] {
        color: #1F2937 !important;
        font-weight: 700 !important;
    }

    /* Bordered containers / chart cards */
    div[data-testid="stVerticalBlock"] > div[data-testid="stVerticalBlockBorderWrapper"] {
        background: #FFFFFF !important;
        border: 1px solid #E5E7EB !important;
        border-radius: 12px;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
    }

    /* Chart card titles */
    div[data-testid="stVerticalBlockBorderWrapper"] strong {
        color: #1F2937 !important;
    }

    /* Buttons */
    button[kind="primary"], .stButton > button {
        background: linear-gradient(135deg, #29B5E8 0%, #1A9AD0 100%) !important;
        color: #FFFFFF !important;
        border: none !important;
        border-radius: 8px !important;
        font-weight: 600 !important;
    }
    button[kind="primary"]:hover, .stButton > button:hover {
        background: linear-gradient(135deg, #1A9AD0 0%, #1584B5 100%) !important;
    }

    /* Segmented control / pills */
    div[data-testid="stSegmentedControl"] button[aria-pressed="true"] {
        background-color: #29B5E8 !important;
        color: #FFFFFF !important;
    }
    div[data-testid="stSegmentedControl"] button {
        color: #6B7280 !important;
        border-color: #E5E7EB !important;
    }

    /* Dataframe */
    div[data-testid="stDataFrame"] thead th {
        background-color: #F6F9FC !important;
        color: #29B5E8 !important;
        font-weight: 700 !important;
        border-bottom: 2px solid #29B5E8 !important;
    }
    div[data-testid="stDataFrame"] tbody td {
        color: #374151 !important;
    }

    /* Chat messages */
    div[data-testid="stChatMessage"] {
        background: #FFFFFF !important;
        border: 1px solid #E5E7EB;
        border-radius: 12px;
        box-shadow: 0 1px 4px rgba(0, 0, 0, 0.04);
    }

    /* Expanders */
    details {
        background: #FFFFFF !important;
        border: 1px solid #E5E7EB !important;
        border-radius: 10px !important;
    }
    details summary {
        color: #FF6B6B !important;
        font-weight: 600 !important;
    }

    /* Text input / search bars */
    div[data-testid="stTextInput"] input {
        background: #FFFFFF !important;
        border: 1px solid #D1D5DB !important;
        color: #1F2937 !important;
        border-radius: 8px !important;
    }
    div[data-testid="stTextInput"] input:focus {
        border-color: #29B5E8 !important;
        box-shadow: 0 0 0 3px rgba(41, 181, 232, 0.15) !important;
    }
    div[data-testid="stTextInput"] input::placeholder {
        color: #9CA3AF !important;
    }

    /* Selectbox / multiselect */
    div[data-testid="stSelectbox"] > div,
    div[data-testid="stMultiSelect"] > div {
        background: #FFFFFF !important;
        border-color: #D1D5DB !important;
        color: #1F2937 !important;
    }

    /* Slider */
    div[data-testid="stSlider"] [role="slider"] {
        background-color: #29B5E8 !important;
    }

    /* Captions */
    .stCaption p {
        color: #9CA3AF !important;
    }

    /* Progress bars: teal secondary */
    .stProgress > div > div {
        background-color: #4ECDC4 !important;
    }

    /* Error / alert accents: coral */
    div[data-testid="stAlert"] {
        border-left-color: #FF6B6B !important;
    }

    /* Main background */
    .stAppViewContainer {
        background: #F6F9FC;
    }

    /* Scrollbar */
    ::-webkit-scrollbar {
        width: 6px;
    }
    ::-webkit-scrollbar-track {
        background: #F6F9FC;
    }
    ::-webkit-scrollbar-thumb {
        background: #CBD5E1;
        border-radius: 3px;
    }
    ::-webkit-scrollbar-thumb:hover {
        background: #94A3B8;
    }
</style>
""", unsafe_allow_html=True)

conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))


@st.cache_data(ttl=300)
def run_query(sql):
    return conn.query(sql)


def call_agent(agent_fqn, question):
    escaped_q = question.replace("\\", "\\\\").replace('"', '\\"')
    request_body = json.dumps({
        "messages": [
            {
                "role": "user",
                "content": [{"type": "text", "text": escaped_q}],
            }
        ]
    })
    result = conn.query(f"""
        SELECT TRY_PARSE_JSON(
            SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
                '{agent_fqn}',
                '{request_body.replace("'", "''")}'
            )
        ) AS RESPONSE
    """)
    resp = result["RESPONSE"][0]
    if isinstance(resp, str):
        resp = json.loads(resp)
    if "message" in resp and "code" in resp:
        raise RuntimeError(resp["message"])
    content_blocks = resp.get("content", [])
    text_parts = [
        block["text"]
        for block in content_blocks
        if isinstance(block, dict) and block.get("type") == "text"
    ]
    return "\n\n".join(text_parts) if text_parts else "Agent returned no text response."


AGENTS = {
    "Product Matching Agent": {
        "fqn": "HACKATHON.RETAIL.PRODUCT_MATCHING_AGENT",
        "icon": ":material/join_inner:",
        "desc": "Find and verify product matches across retailers",
        "color": "blue",
    },
    "Price Optimization Agent": {
        "fqn": "HACKATHON.RETAIL.PRICE_OPTIMIZATION_AGENT",
        "icon": ":material/trending_up:",
        "desc": "Analyze competitive pricing and suggest optimizations",
        "color": "green",
    },
    "Market Intelligence Agent": {
        "fqn": "HACKATHON.RETAIL.MARKET_INTELLIGENCE_AGENT",
        "icon": ":material/query_stats:",
        "desc": "Detect market trends and strategic insights",
        "color": "orange",
    },
}

# --- Sidebar ---
with st.sidebar:
    st.title(":material/storefront: Retail Intelligence")
    st.caption("AI-Powered Entity Resolution")

    page = st.radio(
        "Navigation",
        [
            ":material/dashboard: Overview",
            ":material/join_inner: Product matches",
            ":material/trending_up: Price analysis",
            ":material/smart_toy: Agent chat",
        ],
        label_visibility="collapsed",
    )

    st.space("medium")
    tier_filter = st.multiselect(
        "Filter by confidence tier",
        ["HIGH", "MEDIUM", "LOW"],
        default=["HIGH", "MEDIUM"],
    )

    st.space("medium")
    with st.expander("Pipeline architecture", icon=":material/account_tree:"):
        st.markdown("""
**Multi-strategy matching**
1. :blue-badge[Vector] Semantic embeddings (cosine similarity)
2. :orange-badge[Fuzzy] Jaro-Winkler string matching
3. :green-badge[LLM] Claude verification & reasoning

**Snowflake stack**
- Cortex Search Service
- 3 Cortex Agents
- Semantic View + Intelligence
- MCP custom tool integration
        """)


tier_clause = (
    "WHERE MATCH_TIER IN ("
    + ",".join(f"'{t}'" for t in tier_filter)
    + ")"
    if tier_filter
    else ""
)
tier_and = "AND" if tier_clause else "WHERE"


# ============================================================
# PAGE: Overview
# ============================================================
if "Overview" in page:
    st.title("Competitive intelligence overview")

    # KPI row
    kpi = run_query(f"""
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN MATCH_TIER='HIGH' THEN 1 ELSE 0 END) as high_ct,
            SUM(CASE WHEN MATCH_TIER='MEDIUM' THEN 1 ELSE 0 END) as med_ct,
            ROUND(AVG(COMBINED_CONFIDENCE)*100,1) as avg_conf,
            ROUND(AVG(ABS(PRICE_GAP_PCT)),1) as avg_gap,
            SUM(CASE WHEN LLM_MATCH THEN 1 ELSE 0 END) as llm_confirmed
        FROM HACKATHON.RETAIL.PRODUCT_MATCHES_FINAL {tier_clause}
    """)
    r = kpi.iloc[0]

    with st.container(horizontal=True):
        st.metric("Total matches", f"{int(r['TOTAL']):,}", border=True)
        st.metric("HIGH confidence", f"{int(r['HIGH_CT']):,}", border=True)
        st.metric("MEDIUM confidence", f"{int(r['MED_CT']):,}", border=True)
        st.metric("Avg confidence", f"{r['AVG_CONF']}%", border=True)
        st.metric("Avg price gap", f"{r['AVG_GAP']}%", border=True)
        st.metric("LLM confirmed", f"{int(r['LLM_CONFIRMED']):,}", border=True)

    # Charts row
    col1, col2 = st.columns(2)

    with col1:
        with st.container(border=True):
            st.markdown("**Matches by confidence tier**")
            tier_data = run_query("""
                SELECT MATCH_TIER, COUNT(*) as COUNT
                FROM HACKATHON.RETAIL.PRODUCT_MATCHES_FINAL
                GROUP BY MATCH_TIER ORDER BY COUNT DESC
            """)
            st.bar_chart(tier_data, x="MATCH_TIER", y="COUNT", color="MATCH_TIER", horizontal=True)

    with col2:
        with st.container(border=True):
            st.markdown("**Average score by strategy**")
            strategy = run_query(f"""
                SELECT 'Vector' as STRATEGY, ROUND(AVG(VECTOR_SCORE),3) as SCORE FROM HACKATHON.RETAIL.PRODUCT_MATCHES_FINAL {tier_clause}
                UNION ALL SELECT 'Fuzzy', ROUND(AVG(FUZZY_SCORE),3) FROM HACKATHON.RETAIL.PRODUCT_MATCHES_FINAL {tier_clause}
                UNION ALL SELECT 'LLM', ROUND(AVG(LLM_CONFIDENCE),3) FROM HACKATHON.RETAIL.PRODUCT_MATCHES_FINAL {tier_clause}
                UNION ALL SELECT 'Combined', ROUND(AVG(COMBINED_CONFIDENCE),3) FROM HACKATHON.RETAIL.PRODUCT_MATCHES_FINAL {tier_clause}
            """)
            st.bar_chart(strategy, x="STRATEGY", y="SCORE", horizontal=True)

    # Accuracy + Top manufacturers
    col3, col4 = st.columns(2)

    with col3:
        with st.container(border=True):
            st.markdown("**Accuracy vs ground truth**")
            accuracy = run_query("""
                WITH gt AS (SELECT ABT_ID, BUY_ID FROM HACKATHON.RETAIL.ABT_BUY_PERFECT_MAPPING),
                preds AS (SELECT ABT_ID, BUY_ID, MATCH_TIER FROM HACKATHON.RETAIL.PRODUCT_MATCHES_FINAL)
                SELECT p.MATCH_TIER as TIER, COUNT(*) as PREDICTIONS,
                       SUM(CASE WHEN g.ABT_ID IS NOT NULL THEN 1 ELSE 0 END) as CORRECT,
                       ROUND(SUM(CASE WHEN g.ABT_ID IS NOT NULL THEN 1 ELSE 0 END)/COUNT(*)*100,1) as PRECISION_PCT
                FROM preds p LEFT JOIN gt g ON p.ABT_ID=g.ABT_ID AND p.BUY_ID=g.BUY_ID
                GROUP BY p.MATCH_TIER ORDER BY PRECISION_PCT DESC
            """)
            st.dataframe(
                accuracy, hide_index=True, use_container_width=True,
                column_config={
                    "PRECISION_PCT": st.column_config.ProgressColumn(
                        "Precision", min_value=0, max_value=100, format="%.1f%%"
                    ),
                },
            )

    with col4:
        with st.container(border=True):
            st.markdown("**Top brands by match count**")
            brands = run_query(f"""
                SELECT MANUFACTURER as BRAND, COUNT(*) as MATCHES,
                       ROUND(AVG(COMBINED_CONFIDENCE),3) as AVG_CONF
                FROM HACKATHON.RETAIL.PRODUCT_MATCHES_FINAL
                {tier_clause} {tier_and} MANUFACTURER IS NOT NULL AND MANUFACTURER != ''
                GROUP BY MANUFACTURER ORDER BY MATCHES DESC LIMIT 10
            """)
            st.bar_chart(brands, x="BRAND", y="MATCHES")


# ============================================================
# PAGE: Product matches
# ============================================================
elif "matches" in page:
    st.title("Product matches explorer")

    search_col, filter_col = st.columns([3, 1])
    with search_col:
        search = st.text_input(
            "Search products",
            placeholder="Search by name, brand, or keyword...",
            label_visibility="collapsed",
        )
    with filter_col:
        llm_filter = st.selectbox("LLM status", ["All", "Confirmed", "Rejected"])

    search_clause = f"AND (ABT_NAME ILIKE '%{search}%' OR BUY_NAME ILIKE '%{search}%' OR MANUFACTURER ILIKE '%{search}%')" if search else ""
    llm_clause = ""
    if llm_filter == "Confirmed":
        llm_clause = "AND LLM_MATCH = TRUE"
    elif llm_filter == "Rejected":
        llm_clause = "AND LLM_MATCH = FALSE"

    matches = run_query(f"""
        SELECT ABT_NAME, BUY_NAME, MANUFACTURER,
               ROUND(VECTOR_SCORE,3) as VECTOR, ROUND(FUZZY_SCORE,3) as FUZZY,
               ROUND(LLM_CONFIDENCE,2) as LLM, COMBINED_CONFIDENCE as COMBINED,
               MATCH_TIER, LLM_MATCH,
               ABT_PRICE, BUY_PRICE, ROUND(PRICE_GAP_PCT,1) as GAP_PCT
        FROM HACKATHON.RETAIL.PRODUCT_MATCHES_FINAL
        {tier_clause} {search_clause} {llm_clause}
        ORDER BY COMBINED_CONFIDENCE DESC LIMIT 200
    """)

    st.caption(f"{len(matches)} matches shown")
    st.dataframe(
        matches, hide_index=True, use_container_width=True,
        column_config={
            "COMBINED": st.column_config.ProgressColumn("Combined", min_value=0, max_value=1, format="%.3f"),
            "VECTOR": st.column_config.NumberColumn(format="%.3f"),
            "FUZZY": st.column_config.NumberColumn(format="%.3f"),
            "LLM": st.column_config.NumberColumn(format="%.2f"),
            "ABT_PRICE": st.column_config.NumberColumn("Abt $", format="$%.2f"),
            "BUY_PRICE": st.column_config.NumberColumn("Buy $", format="$%.2f"),
            "GAP_PCT": st.column_config.NumberColumn("Gap %", format="%.1f%%"),
        },
    )

    # Detail expander for a selected product
    with st.expander("View match reasoning (LLM)", icon=":material/psychology:"):
        if search:
            reasoning = run_query(f"""
                SELECT ABT_NAME, BUY_NAME, LLM_REASON, ROUND(LLM_CONFIDENCE,2) as CONF, LLM_MATCH
                FROM HACKATHON.RETAIL.PRODUCT_MATCHES_FINAL
                WHERE ABT_NAME ILIKE '%{search}%' OR BUY_NAME ILIKE '%{search}%'
                ORDER BY COMBINED_CONFIDENCE DESC LIMIT 5
            """)
            for _, row in reasoning.iterrows():
                match_badge = ":green-badge[Match]" if row["LLM_MATCH"] else ":red-badge[No match]"
                st.markdown(f"**{row['ABT_NAME']}** vs **{row['BUY_NAME']}** {match_badge} (conf: {row['CONF']})")
                st.caption(row["LLM_REASON"] if row["LLM_REASON"] else "No reason provided")
        else:
            st.caption("Enter a search term above to see LLM reasoning for specific matches.")


# ============================================================
# PAGE: Price analysis
# ============================================================
elif "Price" in page:
    st.title("Competitive pricing analysis")

    # Summary KPIs
    price_kpi = run_query(f"""
        SELECT
            ROUND(AVG(PRICE_DIFFERENCE),2) as AVG_DIFF,
            ROUND(MAX(PRICE_DIFFERENCE),2) as MAX_DIFF,
            SUM(CASE WHEN ABT_PRICE < BUY_PRICE THEN 1 ELSE 0 END) as ABT_WINS,
            SUM(CASE WHEN BUY_PRICE < ABT_PRICE THEN 1 ELSE 0 END) as BUY_WINS
        FROM HACKATHON.RETAIL.PRODUCT_MATCHES_FINAL
        {tier_clause}
        {tier_and} ABT_PRICE IS NOT NULL AND BUY_PRICE IS NOT NULL
    """)
    pk = price_kpi.iloc[0]
    with st.container(horizontal=True):
        st.metric("Avg price difference", f"${pk['AVG_DIFF']}", border=True)
        st.metric("Max price difference", f"${pk['MAX_DIFF']}", border=True)
        st.metric("Abt cheaper", f"{int(pk['ABT_WINS']):,} products", border=True)
        st.metric("Buy cheaper", f"{int(pk['BUY_WINS']):,} products", border=True)

    col1, col2 = st.columns(2)

    with col1:
        with st.container(border=True):
            st.markdown("**Avg price gap by manufacturer**")
            mfr = run_query(f"""
                SELECT MANUFACTURER, COUNT(*) as N,
                       ROUND(AVG(PRICE_DIFFERENCE),2) as AVG_DIFF,
                       ROUND(AVG(ABS(PRICE_GAP_PCT)),1) as AVG_GAP
                FROM HACKATHON.RETAIL.PRODUCT_MATCHES_FINAL
                {tier_clause} {tier_and} MANUFACTURER IS NOT NULL AND MANUFACTURER != ''
                GROUP BY MANUFACTURER HAVING COUNT(*) >= 3 ORDER BY AVG_DIFF DESC LIMIT 12
            """)
            st.bar_chart(mfr, x="MANUFACTURER", y="AVG_DIFF")

    with col2:
        with st.container(border=True):
            st.markdown("**Who is cheaper?**")
            cheaper = run_query(f"""
                SELECT CASE WHEN ABT_PRICE < BUY_PRICE THEN 'Abt Cheaper'
                            WHEN BUY_PRICE < ABT_PRICE THEN 'Buy Cheaper'
                            ELSE 'Same Price' END as RETAILER, COUNT(*) as COUNT
                FROM HACKATHON.RETAIL.PRODUCT_MATCHES_FINAL
                {tier_clause} {tier_and} ABT_PRICE IS NOT NULL AND BUY_PRICE IS NOT NULL
                GROUP BY 1 ORDER BY COUNT DESC
            """)
            st.bar_chart(cheaper, x="RETAILER", y="COUNT", color="RETAILER")

    with st.container(border=True):
        st.markdown("**Biggest price gaps**")
        gaps = run_query(f"""
            SELECT ABT_NAME, BUY_NAME, ABT_PRICE, BUY_PRICE,
                   ROUND(PRICE_DIFFERENCE,2) as DIFF, ROUND(PRICE_GAP_PCT,1) as GAP
            FROM HACKATHON.RETAIL.PRODUCT_MATCHES_FINAL
            {tier_clause} {tier_and} ABT_PRICE IS NOT NULL AND BUY_PRICE IS NOT NULL
            ORDER BY PRICE_DIFFERENCE DESC LIMIT 20
        """)
        st.dataframe(
            gaps, hide_index=True, use_container_width=True,
            column_config={
                "ABT_PRICE": st.column_config.NumberColumn("Abt $", format="$%.2f"),
                "BUY_PRICE": st.column_config.NumberColumn("Buy $", format="$%.2f"),
                "DIFF": st.column_config.NumberColumn("Diff $", format="$%.2f"),
                "GAP": st.column_config.NumberColumn("Gap %", format="%.1f%%"),
            },
        )


# ============================================================
# PAGE: Agent chat
# ============================================================
elif "Agent" in page:
    st.title("Retail intelligence agents")

    # Agent selector as cards
    agent_cols = st.columns(3)
    for i, (name, info) in enumerate(AGENTS.items()):
        with agent_cols[i]:
            with st.container(border=True):
                st.markdown(f"**{info['icon']} {name}**")
                st.caption(info["desc"])

    selected_agent = st.segmented_control(
        "Choose an agent",
        list(AGENTS.keys()),
        default="Product Matching Agent",
        label_visibility="collapsed",
    )
    agent_info = AGENTS[selected_agent]

    st.space("small")

    # Separate chat state per agent
    state_key = f"chat_{selected_agent}"
    if state_key not in st.session_state:
        st.session_state[state_key] = []

    # Display chat history
    for msg in st.session_state[state_key]:
        avatar = ":material/person:" if msg["role"] == "user" else agent_info["icon"]
        with st.chat_message(msg["role"], avatar=avatar):
            st.markdown(msg["content"])

    # Suggestion chips when chat is empty
    if not st.session_state[state_key]:
        suggestions = {
            "Product Matching Agent": {
                ":blue[:material/search:] Top matches": "What are the top 10 highest confidence product matches?",
                ":blue[:material/compare:] Strategy comparison": "Compare vector vs fuzzy vs LLM accuracy across all matches",
                ":blue[:material/category:] Canon products": "Find all Canon product matches and their confidence scores",
            },
            "Price Optimization Agent": {
                ":green[:material/attach_money:] Biggest gaps": "Which products have the biggest price difference between Abt and Buy?",
                ":green[:material/factory:] Brand pricing": "Compare average pricing by manufacturer across both retailers",
                ":green[:material/lightbulb:] Recommendations": "Which products should Abt reprice to be more competitive?",
            },
            "Market Intelligence Agent": {
                ":orange[:material/analytics:] Market overview": "Give me an overall market intelligence summary",
                ":orange[:material/trending_up:] Accuracy trends": "How does matching accuracy break down by confidence tier?",
                ":orange[:material/inventory:] Coverage gaps": "Which product categories have the least matching coverage?",
            },
        }
        agent_suggestions = suggestions.get(selected_agent, {})
        selected = st.pills(
            "Try asking",
            list(agent_suggestions.keys()),
            label_visibility="collapsed",
        )
        if selected:
            prompt = agent_suggestions[selected]
            st.session_state[state_key].append({"role": "user", "content": prompt})
            st.rerun()

    # Chat input
    if prompt := st.chat_input(f"Ask {selected_agent}..."):
        st.session_state[state_key].append({"role": "user", "content": prompt})
        with st.chat_message("user", avatar=":material/person:"):
            st.markdown(prompt)

        with st.chat_message("assistant", avatar=agent_info["icon"]):
            with st.spinner("Agent is thinking..."):
                try:
                    response = call_agent(agent_info["fqn"], prompt)
                    st.markdown(response)
                    st.session_state[state_key].append({"role": "assistant", "content": response})
                except Exception as e:
                    st.error(f"Agent error: {e}", icon=":material/error:")
