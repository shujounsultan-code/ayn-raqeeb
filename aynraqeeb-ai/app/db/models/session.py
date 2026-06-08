import uuid
from sqlalchemy import Column, String, DateTime, func, JSON, Uuid
from app.db.database import Base


class ChatSession(Base):
    """جلسات محادثة أولياء الأمور"""
    __tablename__ = "chat_sessions"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id = Column(String, nullable=False)         # ID ولي الأمر من تطبيق AynRaqeeb
    history = Column(JSON, default=list)            # قائمة الرسائل [{role, content}]
    started_at = Column(DateTime(timezone=True), server_default=func.now())
    last_active = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
