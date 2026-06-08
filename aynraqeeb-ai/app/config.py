from pydantic_settings import BaseSettings
from typing import Literal


class Settings(BaseSettings):
    # عام
    APP_NAME: str = "AynRaqeeb AI Service"
    DEBUG: bool = False

    # قاعدة البيانات (SQLite الخفيفة)
    DATABASE_URL: str = "sqlite+aiosqlite:///./aynraqeeb.db"

    # إعدادات Groq
    GROQ_API_KEY: str | None = None
    GROQ_CHAT_MODEL: str = "openai/gpt-oss-20b"

    # الأمان
    API_KEY: str

    # LLM Provider
    LLM_PROVIDER: Literal["openai", "gemini", "groq"] = "openai"

    # OpenAI
    OPENAI_API_KEY: str = ""
    OPENAI_CHAT_MODEL: str = "gpt-4o"
    OPENAI_EMBEDDING_MODEL: str = "text-embedding-3-small"

    # Gemini
    GEMINI_API_KEY: str = ""
    GEMINI_CHAT_MODEL: str = "gemini-1.5-flash"
    GEMINI_EMBEDDING_MODEL: str = "models/text-embedding-004"

    # إعدادات RAG
    CHUNK_SIZE: int = 500
    CHUNK_OVERLAP: int = 50
    TOP_K_RESULTS: int = 5
    RERANK_RESULTS: int = 20  # عدد النتائج التي يتم جلبها قبل إعادة الترتيب
    USE_RERANKER: bool = True

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
