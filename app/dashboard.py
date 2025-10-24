# ===========================================
# dashboard.py  –  Panel Streamlit Distribuidor
# ===========================================

import streamlit as st
import pandas as pd
import psycopg2
import plotly.express as px
from psycopg2.extras import RealDictCursor

# -------------------------------
# 🧩 Configuración de conexión
# -------------------------------
DB_CONFIG = {
    "host": "localhost",
    "dbname": "distributor_db_utf8",
    "user": "postgres",
    "password": "Faccaf21$",
    "port": 5432,
    "options": "-c client_encoding=LATIN1"
}

# -------------------------------
# 📡 Función de conexión
# -------------------------------
@st.cache_data(ttl=300)
def run_query(query):
    conn = psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)
    with conn.cursor() as cur:
        cur.execute(query)
        rows = cur.fetchall()
    conn.close()
    return pd.DataFrame(rows)

# -------------------------------
# 🧭 Layout principal
# -------------------------------
st.set_page_config(
    page_title="Panel Distribuidor",
    layout="wide",
    page_icon="📦"
)

st.title("📦 Panel de Control – Distribución Mayorista")
st.markdown("### Datos sincronizados desde *PostgreSQL → public schema*")

# -------------------------------
# 🔍 Cargar métricas principales
# -------------------------------
try:
    df_products = run_query("SELECT COUNT(*) AS total FROM public.products;")
    df_clients = run_query("SELECT COUNT(*) AS total FROM public.clients;")
    df_orders = run_query("SELECT COUNT(*) AS total FROM public.orders;")
    df_items = run_query("""
        SELECT SUM(quantity * unit_price_net) AS total_sales
        FROM public.order_items;
    """)

    total_products = int(df_products.iloc[0]["total"])
    total_clients = int(df_clients.iloc[0]["total"])
    total_orders = int(df_orders.iloc[0]["total"])
    total_sales = round(df_items.iloc[0]["total_sales"] or 0, 2)

    # KPIs
    col1, col2, col3, col4 = st.columns(4)
    col1.metric("🛍️ Productos", total_products)
    col2.metric("👥 Clientes", total_clients)
    col3.metric("📦 Pedidos", total_orders)
    col4.metric("💶 Ventas (€)", f"{total_sales:,.2f}")

except Exception as e:
    st.error(f"Error al conectar con la base de datos: {e}")
    st.stop()

# -------------------------------
# 📈 Gráfico de ventas mensuales
# -------------------------------
st.markdown("## 📈 Ventas por mes")
try:
    df_sales = run_query("""
        SELECT DATE_TRUNC('month', order_date) AS mes,
               SUM(total_gross) AS ventas
        FROM public.orders
        GROUP BY mes
        ORDER BY mes;
    """)
    if not df_sales.empty:
        fig = px.bar(df_sales, x="mes", y="ventas",
                     title="Evolución mensual de ventas (€)",
                     labels={"mes": "Mes", "ventas": "Ventas (€)"},
                     text_auto=".2s",
                     color="ventas")
        st.plotly_chart(fig, use_container_width=True)
except Exception as e:
    st.warning(f"No se pudo generar gráfico: {e}")

# -------------------------------
# 📊 Tablas principales
# -------------------------------
st.markdown("## 📊 Datos Detallados")

tabs = st.tabs(["Productos", "Clientes", "Pedidos", "Items"])

with tabs[0]:
    st.dataframe(run_query("SELECT * FROM public.products LIMIT 100;"))

with tabs[1]:
    st.dataframe(run_query("SELECT * FROM public.clients LIMIT 100;"))

with tabs[2]:
    st.dataframe(run_query("SELECT * FROM public.orders LIMIT 100;"))

with tabs[3]:
    st.dataframe(run_query("""
        SELECT o.id AS order_id, p.name AS product, oi.quantity, oi.unit_price_net,
               (oi.quantity * oi.unit_price_net) AS subtotal
        FROM public.order_items oi
        JOIN public.orders o ON oi.order_id = o.id
        JOIN public.products p ON oi.product_id = p.id
        LIMIT 100;
    """))

# -------------------------------
# 🎯 Footer
# -------------------------------
st.markdown("---")
st.caption("© 2025 Distribución Demo | Dashboard Streamlit + PostgreSQL")
