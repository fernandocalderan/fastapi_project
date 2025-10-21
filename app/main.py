from fastapi import FastAPI
from . import models
from .database import engine
from .routers import users

# Crear las tablas si no existen
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="FastAPI + PostgreSQL Demo")

# Incluir las rutas
app.include_router(users.router)

@app.get("/")
def root():
    return {"message": "API funcionando correctamente 🚀"}
