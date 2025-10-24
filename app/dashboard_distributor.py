import os
import streamlit as st
import pandas as pd
from sqlalchemy import create_engine
import plotly.express as px

# =======================================
# ⚙️ CONFIGURACIÓN Y FIX DE CODIFICACIÓN
# =======================================
os.environ["PYTHONIOENCODING"] = "utf-8"
os.environ["PGCLIENTENCODING"] = "latin1"  # los datos están en ISO-8859-1

# =======================================
# 🔗 CONEXIÓN A POSTGRESQL
# =======================================
DB_USER = "postgres"
DB_PASS = "tu_password"   # ← pon tu contraseña real
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "distributor_db"

# Forzar conexión con latin1 (para leer acentos antiguos)
engine = create_engine(
    f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}",
    connect_args={"client_encoding": "LATIN1"}
)

# =======================================
# 📊 FUNCIÓN DE CARGA DE DATOS
# =======================================
@st.cache_data
def load_data():
    query_list = {
        "products": "SELECT id, name, unit_price, supplier_id, category_id, vat_rate FROM public.products",
        "orders": "SELECT id, customer_id, order_date, status, total_amount FROM public.orders",
        "order_items": "SELECT order_id, product_id, quantity, unit_price FROM public.order_items",
        "customers": "SELECT id, name, city, country FROM public.customers",
        "suppliers": "SELECT id, name, city, country FROM public.suppliers",
        "shipments": "SELECT id, order_id, warehouse_id, delivery_status FROM public.shipments",
        "warehouses": "SELECT id, name, city FROM public.warehouses",
        "inventories": "SELECT warehouse_id, quantity_on_hand FROM public.inventories"
    }

    data = {}
    for key, query in query_list.items():
        try:
            df = pd.read_sql(query, engine)
            # Convertimos internamente a UTF-8 limpio
            df = df.applymap(lambda x: x.encode("latin1").decode("utf-8") if isinstance(x, str) else x)
            data[key] = df
        except Exception as e:
            st.error(f"Error cargando {key}: {e}")
    return data

data = load_data()

if "customers" not in data:
    st.error("No se pudo cargar correctamente la base de datos. Verifica conexión o codificación.")
    st.stop()

# =======================================
# 🧭 SIDEBAR
# =======================================
st.sidebar.title("📦 Distributor Analytics")
selected_city = st.sidebar.selectbox(
    "Filtrar por ciudad de cliente:",
    ["Todas"] + sorted(data["customers"]["city"].dropna().unique())
)
selected_status = st.sidebar.multiselect(
    "Estado del pedido:",
    ["pendiente", "completado", "entregado", "en tránsito", "retrasado"],
    default=["entregado", "completado"]
)

# =======================================
# 🧮 PREPARACIÓN DE DATOS
# =======================================
orders = data["orders"].copy()
if selected_status:
    orders = orders[orders["status"].str.lower().isin(selected_status)]

if selected_city != "Todas":
    customer_ids = data["customers"].query("city == @selected_city")["id"]
    orders = orders[orders["customer_id"].isin(customer_ids)]

merged = (
    data["order_items"]
    .merge(orders, left_on="order_id", right_on="id")
    .merge(data["products"], left_on="product_id", right_on="id", suffixes=("_oi", "_p"))
)

merged["total_line"] = merged["quantity"] * merged["unit_price_oi"]
merged["order_date"] = pd.to_datetime(merged["order_date"], errors="coerce")
merged["month"] = merged["order_date"].dt.to_period("M").astype(str)

# =======================================
# 🧾 PESTAÑAS DE DASHBOARD
# =======================================
tabs = st.tabs(["📊 General", "💰 Análisis Financiero"])

# =======================================
# 🧱 TAB 1: GENERAL
# =======================================
with tabs[0]:
    st.title("📊 Panel General de Distribución Alimentaria")
    st.markdown("Datos generados desde `seed_distributor_db_full.sql`")

    # KPIs principales
    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Ventas Totales (€)", f"{merged['total_line'].sum():,.2f}")
    col2.metric("Pedidos", len(orders))
    col3.metric("Clientes", len(data["customers"]))
    col4.metric("Productos", len(data["products"]))

    # Ventas por mes
    if not merged.empty:
        sales_month = merged.groupby("month")["total_line"].sum().reset_index()
        fig1 = px.bar(sales_month, x="month", y="total_line", title="Evolución mensual de ventas (€)")
        st.plotly_chart(fig1, use_container_width=True)

        # Top 10 productos
        top_products = (
            merged.groupby("name")["quantity"]
            .sum()
            .sort_values(ascending=False)
            .head(10)
            .reset_index()
        )
        fig2 = px.bar(top_products, x="quantity", y="name", orientation="h", title="Top 10 productos más vendidos")
        st.plotly_chart(fig2, use_container_width=True)
    else:
        st.warning("No hay datos disponibles para los filtros seleccionados.")

    # Distribución de clientes
    client_city = data["customers"]["city"].value_counts().reset_index()
    client_city.columns = ["city", "clientes"]
    fig3 = px.pie(client_city, names="city", values="clientes", title="Distribución de clientes por ciudad")
    st.plotly_chart(fig3, use_container_width=True)

    # Estado de envíos
    shipment_status = data["shipments"]["delivery_status"].value_counts().reset_index()
    shipment_status.columns = ["Estado", "Cantidad"]
    fig4 = px.pie(shipment_status, names="Estado", values="Cantidad", title="Estado actual de los envíos")
    st.plotly_chart(fig4, use_container_width=True)

    # Stock por almacén
    inv = data["inventories"].merge(data["warehouses"], left_on="warehouse_id", right_on="id")
    inv_sum = inv.groupby("name")["quantity_on_hand"].sum().reset_index()
    fig5 = px.bar(inv_sum, x="name", y="quantity_on_hand", title="Stock total por almacén", color="name")
    st.plotly_chart(fig5, use_container_width=True)

# =======================================
# 💰 TAB 2: ANÁLISIS FINANCIERO
# =======================================
with tabs[1]:
    st.title("💰 Análisis Financiero y Rentabilidad")

    # Margen promedio
    margin_avg = data["products"]["unit_price"].mean() * 0.25  # proxy
    total_sales = merged["total_line"].sum()
    vat_total = merged["total_line"].sum() * 0.10  # estimado 10%
    profit_est = total_sales - vat_total

    c1, c2, c3 = st.columns(3)
    c1.metric("Ingresos netos (€)", f"{total_sales:,.2f}")
    c2.metric("IVA estimado (€)", f"{vat_total:,.2f}")
    c3.metric("Beneficio neto estimado (€)", f"{profit_est:,.2f}")

    # Rentabilidad por proveedor
    supplier_perf = (
        merged.merge(data["suppliers"], left_on="supplier_id", right_on="id", suffixes=("", "_sup"))
        .groupby("name_sup")["total_line"]
        .sum()
        .sort_values(ascending=False)
        .head(10)
        .reset_index()
    )
    fig6 = px.bar(supplier_perf, x="total_line", y="name_sup", orientation="h", title="Top proveedores por volumen (€)")
    st.plotly_chart(fig6, use_container_width=True)

    # Proyección de ingresos anual (simple)
    monthly = merged.groupby("month")["total_line"].sum().reset_index()
    if len(monthly) >= 3:
        growth_rate = (monthly["total_line"].iloc[-1] / monthly["total_line"].iloc[0]) ** (1 / len(monthly)) - 1
        projected = total_sales * (1 + growth_rate) ** 12
    else:
        projected = total_sales

    st.metric("Proyección anual de ingresos (€)", f"{projected:,.2f}")

st.markdown("---")
st.markdown("**Desarrollado por Kairos DataLab · PostgreSQL + Streamlit + Plotly**")
