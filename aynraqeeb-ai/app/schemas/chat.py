from pydantic import BaseModel
from typing import Optional


class ChatRequest(BaseModel):
    user_id: str
    message: str
    session_id: Optional[str] = None
    live_context: Optional[str] = None  # بيانات موقع الباص الحية من Flutter

    model_config = {
        "json_schema_extra": {
            "example": {
                "user_id": "parent_123",
                "message": "متى تصل الحافلة اليوم؟",
                "session_id": None,
                "live_context": "موقع الباص الحالي: خط العرض 24.71، خط الطول 46.67\nموقع البيت: خط العرض 24.75، خط الطول 46.70\nالمسافة التقريبية: 2.3 كم",
            }
        }
    }


class ChatResponse(BaseModel):
    session_id: str
    answer: str
    sources_count: int

    model_config = {
        "json_schema_extra": {
            "example": {
                "session_id": "550e8400-e29b-41d4-a716-446655440000",
                "answer": "بناءً على جدول الرحلات، تصل الحافلة بين الساعة 7:00 و7:15 صباحاً.",
                "sources_count": 3,
            }
        }
    }


class SessionHistoryResponse(BaseModel):
    session_id: str
    user_id: str
    history: list[dict]
