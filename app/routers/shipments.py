from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import crud, schemas
from ..dependencies import get_db


router = APIRouter(prefix="/shipments", tags=["shipments"])


@router.get("/", response_model=list[schemas.Shipment])
def list_shipments(status: str | None = None, db: Session = Depends(get_db)):
    return crud.get_shipments(db, status=status)


@router.get("/{shipment_id}", response_model=schemas.Shipment)
def get_shipment(shipment_id: int, db: Session = Depends(get_db)):
    shipment = crud.get_shipment(db, shipment_id)
    if shipment is None:
        raise HTTPException(status_code=404, detail="Envío no encontrado")
    return shipment
