from pydantic import BaseModel
from typing import Literal, Optional


# ─────────────────── LLM Test ───────────────────

class LLMTestRequest(BaseModel):
    provider: Literal["openai", "gemini", "groq"]
    api_key: str
    model: Optional[str] = None   # اختياري — إذا فارغ يستخدم الافتراضي

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "summary": "اختبار OpenAI",
                    "value": {
                        "provider": "openai",
                        "api_key": "sk-...",
                        "model": "gpt-4o",
                    },
                },
                {
                    "summary": "اختبار Gemini",
                    "value": {
                        "provider": "gemini",
                        "api_key": "AIza...",
                        "model": "gemini-1.5-flash",
                    },
                },
            ]
        }
    }


class LLMTestResponse(BaseModel):
    success: bool
    provider: str
    model: str
    response: str          # رد تجريبي من الـ LLM
    error: Optional[str] = None


# ─────────────────── Prompt ───────────────────

class PromptUpdateRequest(BaseModel):
    prompt: str

    model_config = {
        "json_schema_extra": {
            "example": {
                "prompt": (
                    "أنت مساعد ذكي لتطبيق عين رقيب لخدمة أولياء الأمور.\n"
                    "أجب باللغة العربية دائماً.\n"
                    "ساعد ولي الأمر في الاستفسار عن مواعيد الحافلة والحضور."
                )
            }
        }
    }


class PromptResponse(BaseModel):
    prompt: str
    updated_at: Optional[str] = None
