import uuid
from sqlalchemy import Column, String, Integer, Text, ForeignKey, JSON, Uuid
from app.db.database import Base


class Chunk(Base):
    """القطع النصية (Chunks) المستخرجة من الوثائق"""
    __tablename__ = "chunks"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4)
    document_id = Column(Uuid, ForeignKey("documents.id", ondelete="CASCADE"), nullable=False)
    content = Column(Text, nullable=False)           # محتوى القطعة النصية
    chunk_index = Column(Integer, nullable=False)    # ترتيب القطعة في الوثيقة
    embedding = Column(JSON, nullable=True)          # الـ Vector الخاص بالقطعة (اختياري لوجود ChromaDB)
