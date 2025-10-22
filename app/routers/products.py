from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import crud, schemas
from ..dependencies import get_db


router = APIRouter(prefix="/products", tags=["products"])


@router.get("/", response_model=list[schemas.Product])
def list_products(
    supplier_id: int | None = None,
    category_id: int | None = None,
    only_active: bool = False,
    db: Session = Depends(get_db),
):
    return crud.get_products(
        db,
        supplier_id=supplier_id,
        category_id=category_id,
        only_active=only_active,
    )


@router.get("/{product_id}", response_model=schemas.Product)
def get_product(product_id: int, db: Session = Depends(get_db)):
    product = crud.get_product(db, product_id)
    if product is None:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    return product
