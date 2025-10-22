from typing import Optional

from sqlalchemy.orm import Session

from . import models


def get_suppliers(db: Session):
    return db.query(models.Supplier).order_by(models.Supplier.name).all()


def get_supplier(db: Session, supplier_id: int):
    return db.query(models.Supplier).filter(models.Supplier.id == supplier_id).first()


def get_categories(db: Session):
    return db.query(models.Category).order_by(models.Category.name).all()


def get_category(db: Session, category_id: int):
    return db.query(models.Category).filter(models.Category.id == category_id).first()


def get_products(
    db: Session,
    supplier_id: Optional[int] = None,
    category_id: Optional[int] = None,
    only_active: bool = False,
):
    query = db.query(models.Product)
    if supplier_id is not None:
        query = query.filter(models.Product.supplier_id == supplier_id)
    if category_id is not None:
        query = query.filter(models.Product.category_id == category_id)
    if only_active:
        query = query.filter(models.Product.is_active == "Y")
    return query.order_by(models.Product.name).all()


def get_product(db: Session, product_id: int):
    return db.query(models.Product).filter(models.Product.id == product_id).first()


def get_warehouses(db: Session):
    return db.query(models.Warehouse).order_by(models.Warehouse.name).all()


def get_warehouse(db: Session, warehouse_id: int):
    return db.query(models.Warehouse).filter(models.Warehouse.id == warehouse_id).first()


def get_inventory(
    db: Session,
    warehouse_id: Optional[int] = None,
    product_id: Optional[int] = None,
):
    query = db.query(models.Inventory)
    if warehouse_id is not None:
        query = query.filter(models.Inventory.warehouse_id == warehouse_id)
    if product_id is not None:
        query = query.filter(models.Inventory.product_id == product_id)
    return query.order_by(models.Inventory.id).all()


def get_customers(db: Session):
    return db.query(models.Customer).order_by(models.Customer.name).all()


def get_customer(db: Session, customer_id: int):
    return db.query(models.Customer).filter(models.Customer.id == customer_id).first()


def get_orders(db: Session, status: Optional[str] = None):
    query = db.query(models.Order)
    if status:
        query = query.filter(models.Order.status == status)
    return query.order_by(models.Order.order_date.desc()).all()


def get_order(db: Session, order_id: int):
    return db.query(models.Order).filter(models.Order.id == order_id).first()


def get_shipments(db: Session, status: Optional[str] = None):
    query = db.query(models.Shipment)
    if status:
        query = query.filter(models.Shipment.delivery_status == status)
    return query.order_by(models.Shipment.shipped_at.desc().nullslast()).all()


def get_shipment(db: Session, shipment_id: int):
    return db.query(models.Shipment).filter(models.Shipment.id == shipment_id).first()
