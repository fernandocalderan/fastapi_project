from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from .. import crud, schemas
from ..dependencies import get_db


router = APIRouter(prefix="/inventory", tags=["inventory"])


@router.get("/", response_model=list[schemas.Inventory])
def list_inventory(
    warehouse_id: int | None = None,
    product_id: int | None = None,
    db: Session = Depends(get_db),
):
    return crud.get_inventory(db, warehouse_id=warehouse_id, product_id=product_id)
