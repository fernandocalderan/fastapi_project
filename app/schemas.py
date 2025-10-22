from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel


class SupplierBase(BaseModel):
    name: str
    contact_name: str | None = None
    phone: str | None = None
    email: str | None = None
    address: str | None = None
    city: str | None = None
    country: str | None = None


class Supplier(SupplierBase):
    id: int

    class Config:
        orm_mode = True


class SupplierSummary(BaseModel):
    id: int
    name: str

    class Config:
        orm_mode = True


class CategoryBase(BaseModel):
    name: str
    description: str | None = None


class Category(CategoryBase):
    id: int

    class Config:
        orm_mode = True


class CategorySummary(BaseModel):
    id: int
    name: str

    class Config:
        orm_mode = True


class ProductBase(BaseModel):
    name: str
    sku: str | None = None
    unit: str
    unit_price: Decimal
    supplier_id: int | None = None
    category_id: int | None = None
    is_active: str | None = None


class Product(ProductBase):
    id: int
    supplier: SupplierSummary | None = None
    category: CategorySummary | None = None

    class Config:
        orm_mode = True


class ProductSummary(BaseModel):
    id: int
    name: str
    sku: str | None = None

    class Config:
        orm_mode = True


class WarehouseBase(BaseModel):
    name: str
    address: str | None = None
    city: str | None = None
    manager_name: str | None = None


class Warehouse(WarehouseBase):
    id: int

    class Config:
        orm_mode = True


class WarehouseSummary(BaseModel):
    id: int
    name: str
    city: str | None = None

    class Config:
        orm_mode = True


class Inventory(BaseModel):
    id: int
    product: ProductSummary
    warehouse: WarehouseSummary
    quantity_on_hand: int
    safety_stock: int | None = None
    last_restocked: date | None = None

    class Config:
        orm_mode = True


class CustomerBase(BaseModel):
    name: str
    contact_name: str | None = None
    phone: str | None = None
    email: str | None = None
    address: str | None = None
    city: str | None = None
    country: str | None = None


class Customer(CustomerBase):
    id: int

    class Config:
        orm_mode = True


class CustomerSummary(BaseModel):
    id: int
    name: str

    class Config:
        orm_mode = True


class OrderItem(BaseModel):
    id: int
    product: ProductSummary
    quantity: int
    unit_price: Decimal
    discount: Decimal | None = None

    class Config:
        orm_mode = True


class Order(BaseModel):
    id: int
    customer: CustomerSummary
    order_date: date
    required_date: date | None = None
    status: str
    total_amount: Decimal
    items: list[OrderItem]

    class Config:
        orm_mode = True


class OrderSummary(BaseModel):
    id: int
    order_date: date
    status: str
    customer: CustomerSummary

    class Config:
        orm_mode = True


class Shipment(BaseModel):
    id: int
    order: OrderSummary
    warehouse: WarehouseSummary | None = None
    shipped_at: datetime | None = None
    estimated_delivery: date | None = None
    delivery_status: str
    tracking_number: str | None = None

    class Config:
        orm_mode = True
