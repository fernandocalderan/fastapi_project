# 🧠 DEV PLAN TÉCNICO — DASHBOARD DISTRIBUIDOR MAYORISTA

## 🎯 Objetivo
Desarrollar un **dashboard integral y operativo** para la gestión y análisis de un negocio distribuidor mayorista (clientes, productos, proveedores, trabajadores, ventas y rendimiento).  
El sistema permitirá registro, análisis individual, análisis global, alertas, reportes y visualización de datos, todo en entorno web interactivo (Streamlit + PostgreSQL + Plotly).

---

## 🏗️ Arquitectura General

| Capa | Tecnología | Descripción |
|------|-------------|--------------|
| **Frontend / UI** | Streamlit + Plotly + Tailwind Theme CSS | Dashboards dinámicos, formularios, paneles de análisis |
| **Backend / API** | FastAPI + Pydantic + SQLAlchemy | Lógica de negocio, endpoints CRUD, seguridad JWT |
| **Base de Datos** | PostgreSQL 16 | Persistencia, relaciones normalizadas |
| **ETL / Sync Layer** | Python (psycopg2, pandas) | Importación, limpieza y sincronización |
| **Seguridad / Auth** | OAuth 2 + JWT | Roles y control de acceso |
| **Despliegue** | Docker Compose + NGINX Reverse Proxy + SSL | Entorno reproducible y seguro |
| **Monitorización** | Prometheus + Grafana | Métricas de rendimiento del sistema |

---

## 🧩 Módulos Funcionales

### 1️⃣ Módulo Clientes
- CRUD completo: alta, edición, baja, búsqueda avanzada  
- Campos: nombre, tipo, NIF, país, ciudad, dirección, contacto, email, volumen medio, estado  
- Vista individual: pedidos totales, frecuencia, facturación, ranking productos  
- Filtros: región, estado, volumen, fecha alta  
- Exportación a Excel/CSV  

### 2️⃣ Módulo Productos
- CRUD completo  
- Campos: SKU, nombre, marca, categoría, precio, stock, proveedor, margen  
- Filtros: categoría, stock, margen, proveedor  
- Vista individual: ventas, stock por almacén, alertas de rotura  
- Top 10 más vendidos / menos vendidos  

### 3️⃣ Módulo Proveedores
- CRUD completo  
- Campos: nombre, tipo, país, certificaciones, fecha registro, plazos, volumen, estado  
- Vista individual: productos suministrados, tiempos medios, volumen, coste medio  
- Dashboard de proveedores por país (mapa Plotly)  
- Alertas: retrasos > 20 % vs promedio  

### 4️⃣ Módulo Trabajadores
- CRUD completo  
- Campos: nombre, rol, departamento, ciudad, salario, contrato, fecha ingreso  
- Filtros: departamento, rol, salario, antigüedad  
- Vista individual: pedidos gestionados, rendimiento, objetivos  
- Métricas RRHH: rotación, salario medio, productividad  

### 5️⃣ Dashboard General
- KPIs: clientes, productos, proveedores, trabajadores, ventas netas, margen medio  
- Gráfico ventas mensuales  
- Mapa de ventas por ciudad  
- Top Clientes / Top Productos  
- Panel de alertas automáticas  
- Comparador de periodos  
- Filtro global por rango de fechas  

### 6️⃣ Análisis Individual
- Página dedicada con perfil + gráficos  
- Línea de tiempo de transacciones  
- Indicadores de rendimiento  
- Comentarios / seguimiento interno  
- Exportación PDF de informe  

### 7️⃣ Filtros y Segmentación
- Filtros combinados  
- Guardado de segmentos  
- Filtro global por fecha, región, tipo  
- Resultados sincronizados en todos los widgets  

### 8️⃣ Reportes y Exportación
- Exportación Excel/CSV  
- Generación de PDF resumen mensual  
- Reporte automático por correo  
- Integración futura con Google Sheets  

### 9️⃣ Alertas Inteligentes
- Stock crítico  
- Caída de ventas  
- Retrasos proveedores  
- Empleados inactivos  
- Panel de notificaciones  

### 🔟 Autenticación y Roles
- Login / Logout con JWT  
- Roles: Admin, Ventas, Compras, RRHH, Dirección  
- Control de acceso granular  
- Registro de actividad (audit trail)  

---

## ⚙️ Fases de Implementación

| Fase | Enfoque | Entregables |
|------|----------|-------------|
| 1 | Infraestructura & DB | Tablas, esquemas, seeds, entorno Docker |
| 2 | Backend API REST | CRUDs + JWT + SQLAlchemy |
| 3 | Frontend MVP | Streamlit + KPIs iniciales |
| 4 | Análisis & Filtros | Ventas mensuales, top productos |
| 5 | Análisis Individual | Detalles + alertas inteligentes |
| 6 | Reportes & Exportación | PDF/Excel + Email Reports |
| 7 | Seguridad & Roles | Auth completa |
| 8 | Optimización UX/UI | Dark mode + responsive |
| 9 | Deploy & Monitorización | Docker + Prometheus |

---

## 📊 Métricas de Éxito

| Categoría | Indicador | Meta |
|------------|------------|------|
| Rendimiento | Carga dashboard | < 2 s |
| Usabilidad | Satisfacción usuario | ≥ 8/10 |
| Fiabilidad | 0 errores SQL críticos | 100 % |
| Funcionalidad | % módulos MVP | ≥ 80 % |
| Escalabilidad | > 100K registros | OK |
| Integración | API REST abierta | Sí |

---

## 🧭 Siguientes Pasos
1. Diseñar esquema visual y navegación.  
2. Priorizar MVP (Clientes + Productos + Dashboard).  
3. Definir endpoints FastAPI.  
4. Crear prototipo Streamlit inicial.  
5. Iterar con análisis, alertas y reportes.

---

## 🔧 Diagramas Técnicos

### Arquitectura

```mermaid
graph TD
  subgraph Usuario
    U[👤 Comercial / Compras / RRHH / Dirección]
  end

  subgraph UI
    ST[Streamlit\n(UI, filtros, gráficos Plotly)]
  end

  subgraph API
    FA[FastAPI\n(REST, auth JWT)]
    SA[SQLAlchemy\n(ORM + consultas)]
  end

  subgraph DB[(PostgreSQL 16)]
    PUB[(Esquema public)]
    RAW[(Esquema distributor_raw)]
  end

  subgraph Infra
    NGINX[NGINX Proxy]
    DOCKER[Docker Compose]
    MON[Prometheus/Grafana]
  end

  U -->|HTTPS| NGINX --> ST
  ST -->|REST| FA --> SA --> DB
  RAW -->|Sync| PUB
  MON --> NGINX
  MON --> FA
  MON --> DB



Flujo CRUD Cliente
sequenceDiagram
  participant U as Usuario
  participant ST as Streamlit
  participant API as FastAPI
  participant DB as PostgreSQL

  U->>ST: Abre módulo Clientes
  ST->>API: GET /clients
  API->>DB: SELECT * FROM clients
  DB-->>API: datos
  API-->>ST: JSON
  ST-->>U: Tabla + filtros
  U->>ST: Crear cliente
  ST->>API: POST /clients
  API->>DB: INSERT INTO clients
  DB-->>API: OK
  API-->>ST: 201 Created

ETL / Sync Layer
flowchart TB
  SEED[Seed SQL / CSV] --> RAW[(distributor_raw)]
  RAW -->|Transform/Sync| PUB[(public)]
  PUB --> UI[Dashboard Streamlit]

Modelo ER (simplificado)
erDiagram
  CLIENTS ||--o{ ORDERS : tiene
  PRODUCTS ||--o{ ORDER_ITEMS : aparece_en
  ORDERS ||--o{ ORDER_ITEMS : contiene
  PROVIDERS ||--o{ PRODUCTS : suministra
  WORKERS ||--o{ ORDERS : gestiona

  CLIENTS {
    int id PK
    text company_name
    text email
    text city
    numeric annual_volume
    date signup_date
  }

  PRODUCTS {
    int id PK
    text sku
    text name
    numeric unit_price
    int provider_id FK
  }

  PROVIDERS {
    int id PK
    text company_name
    text country
    date registration_date
  }

  ORDERS {
    int id PK
    int client_id FK
    timestamp order_date
    numeric total_gross
  }

  ORDER_ITEMS {
    int id PK
    int order_id FK
    int product_id FK
    int quantity
    numeric unit_price_net
  }

  WORKERS {
    int id PK
    text full_name
    text department
    numeric salary
  }

Navegación UI
flowchart LR
  HOME[🏠 Dashboard] --> KPIs
  HOME --> Ventas
  HOME --> Alertas
  HOME --> Clientes
  HOME --> Productos
  HOME --> Proveedores
  HOME --> Trabajadores
  HOME --> Reports

🔐 Seguridad

JWT con expiración corta

TLS extremo a extremo

Roles por módulo

Audit log

Backups automáticos

📅 Roadmap Resumido
Semana	Objetivo	Entregables
1–2	DB + FastAPI CRUD	Seeds, endpoints
3–4	Dashboard básico	KPIs + tablas
5–6	Alertas + reportes	Vistas avanzadas
7	Roles + Auth	Acceso controlado
8	UX + Deploy	Docker + Monitoreo
📈 Indicadores Clave

Tiempo carga < 2s

99.5 % uptime

100 % consistencia de datos

MVP funcional antes de semana 3