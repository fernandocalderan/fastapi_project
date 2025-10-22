from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import crud, schemas
from ..dependencies import get_db


router = APIRouter(prefix="/warehouses", tags=["warehouses"])


@router.get("/", response_model=list[schemas.Warehouse])
def list_warehouses(db: Session = Depends(get_db)):
    return crud.get_warehouses(db)


@router.get("/{warehouse_id}", response_model=schemas.Warehouse)
def get_warehouse(warehouse_id: int, db: Session = Depends(get_db)):
    warehouse = crud.get_warehouse(db, warehouse_id)
    if warehouse is None:
        raise HTTPException(status_code=404, detail="Almacén no encontrado")
    return warehouse
