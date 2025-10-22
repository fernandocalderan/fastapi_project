from sqlalchemy import Column, Date, DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import relationship

from .database import Base


class Supplier(Base):
    __tablename__ = "suppliers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), nullable=False, index=True)
    contact_name = Column(String(120))
    phone = Column(String(40))
    email = Column(String(150))
    address = Column(String(200))
    city = Column(String(120))
    country = Column(String(120))

    products = relationship("Product", back_populates="supplier")


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(120), nullable=False, unique=True)
    description = Column(String(250))

    products = relationship("Product", back_populates="category")


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), nullable=False, index=True)
    sku = Column(String(60), unique=True, index=True)
    unit = Column(String(40), nullable=False)
    unit_price = Column(Numeric(12, 2), nullable=False)
    supplier_id = Column(Integer, ForeignKey("suppliers.id"))
    category_id = Column(Integer, ForeignKey("categories.id"))
    is_active = Column(String(1), default="Y")

    supplier = relationship("Supplier", back_populates="products")
    category = relationship("Category", back_populates="products")
    inventories = relationship("Inventory", back_populates="product")
    order_items = relationship("OrderItem", back_populates="product")


class Warehouse(Base):
    __tablename__ = "warehouses"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(120), nullable=False, unique=True)
    address = Column(String(200))
    city = Column(String(120))
    manager_name = Column(String(120))

    inventories = relationship("Inventory", back_populates="warehouse")
    shipments = relationship("Shipment", back_populates="warehouse")


class Inventory(Base):
    __tablename__ = "inventories"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    warehouse_id = Column(Integer, ForeignKey("warehouses.id"), nullable=False)
    quantity_on_hand = Column(Integer, nullable=False, default=0)
    safety_stock = Column(Integer, default=0)
    last_restocked = Column(Date)

    product = relationship("Product", back_populates="inventories")
    warehouse = relationship("Warehouse", back_populates="inventories")


class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), nullable=False)
    contact_name = Column(String(120))
    phone = Column(String(40))
    email = Column(String(150))
    address = Column(String(200))
    city = Column(String(120))
    country = Column(String(120))

    orders = relationship("Order", back_populates="customer")


class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=False)
    order_date = Column(Date, nullable=False)
    required_date = Column(Date)
    status = Column(String(40), default="pendiente")
    total_amount = Column(Numeric(12, 2), nullable=False)

    customer = relationship("Customer", back_populates="orders")
    items = relationship("OrderItem", back_populates="order")
    shipments = relationship("Shipment", back_populates="order")


class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity = Column(Integer, nullable=False)
    unit_price = Column(Numeric(12, 2), nullable=False)
    discount = Column(Numeric(5, 2), default=0)

    order = relationship("Order", back_populates="items")
    product = relationship("Product", back_populates="order_items")


class Shipment(Base):
    __tablename__ = "shipments"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    warehouse_id = Column(Integer, ForeignKey("warehouses.id"))
    shipped_at = Column(DateTime)
    estimated_delivery = Column(Date)
    delivery_status = Column(String(40), default="en tránsito")
    tracking_number = Column(String(120))

    order = relationship("Order", back_populates="shipments")
    warehouse = relationship("Warehouse", back_populates="shipments")
