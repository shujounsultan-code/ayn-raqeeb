from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.config import settings
from app.db.database import init_db
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.router import router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """تهيئة قاعدة البيانات والموديلات عند بدء التشغيل"""
    from app.services.llm_service import llm_service
    await init_db()
    llm_service.initialize()
    yield


app = FastAPI(
    title="🤖 AynRaqeeb AI Service",
    description=(
        "نظام الرد الذكي الآلي لتطبيق عين رقيب.\n\n"
        "يوفر إجابات ذكية لأولياء الأمور مبنية على وثائق ومعلومات تطبيق عين رقيب."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

# إعداد CORS للسماح بالطلبات من المتصفحات (Frontend)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)


@app.get("/health", tags=["⚙️ النظام"])
async def health():
    """حالة الخدمة"""
    return {
        "status": "running",
        "service": settings.APP_NAME,
        "llm_provider": settings.LLM_PROVIDER,
    }
