from pydantic import BaseModel

class UserBase(BaseModel):
    name: str
    email: str

class UserCreate(UserBase):
    pass  # Igual que UserBase, pero lo dejamos separado por claridad

class User(UserBase):
    id: int

    class Config:
        orm_mode = True
