from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import crud, schemas
from ..dependencies import get_db


router = APIRouter(prefix="/orders", tags=["orders"])


@router.get("/", response_model=list[schemas.Order])
def list_orders(status: str | None = None, db: Session = Depends(get_db)):
    return crud.get_orders(db, status=status)


@router.get("/{order_id}", response_model=schemas.Order)
def get_order(order_id: int, db: Session = Depends(get_db)):
    order = crud.get_order(db, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    return order
