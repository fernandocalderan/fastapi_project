from fastapi import FastAPI

from . import models
from .database import engine
from .routers import (
    categories,
    customers,
    inventory,
    orders,
    products,
    shipments,
    suppliers,
    warehouses,
)

# Crear las tablas si no existen
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Distribuidora de Alimentos API",
    description="Catálogo y operaciones principales del banco de datos de la distribuidora",
)

# Incluir las rutas
app.include_router(suppliers.router)
app.include_router(categories.router)
app.include_router(products.router)
app.include_router(warehouses.router)
app.include_router(inventory.router)
app.include_router(customers.router)
app.include_router(orders.router)
app.include_router(shipments.router)


@app.get("/")
def root():
    return {"message": "Banco de datos de la distribuidora disponible"}
