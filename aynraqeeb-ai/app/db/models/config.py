import uuid
from sqlalchemy import Column, String, Text, DateTime, func, Uuid
from app.db.database import Base


class SystemConfig(Base):
    """إعدادات النظام — الـ Prompt والـ API Keys"""
    __tablename__ = "system_config"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4)
    key = Column(String, unique=True, nullable=False)   # اسم الإعداد
    value = Column(Text, nullable=False)                 # قيمته
    description = Column(String, nullable=True)          # وصف
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
