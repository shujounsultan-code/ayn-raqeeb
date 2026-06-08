import uuid
from sqlalchemy import Column, String, DateTime, func, Uuid
from app.db.database import Base


class Document(Base):
    """الوثائق المرفوعة (PDF/Word/TXT)"""
    __tablename__ = "documents"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)           # اسم الملف
    file_type = Column(String, nullable=False)       # pdf | docx | txt
    status = Column(String, default="processing")    # processing | ready | failed
    created_at = Column(DateTime(timezone=True), server_default=func.now())
