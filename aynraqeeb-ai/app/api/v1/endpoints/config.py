from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.security import verify_api_key
from app.db.database import get_db
from app.db.models.config import SystemConfig
from app.schemas.config import (
    LLMTestRequest, LLMTestResponse,
    PromptUpdateRequest, PromptResponse,
)
from app.services.rag_pipeline import DEFAULT_PROMPT

router = APIRouter(prefix="/config", tags=["⚙️ الإعدادات والاختبار"])

PROMPT_KEY = "parent_system_prompt"
TEST_QUESTION = "مرحباً، هل أنت جاهز للمساعدة؟"


# ══════════════════════════════════════════════════════
#   LLM — اختبار الاتصال وإضافة الـ API Key
# ══════════════════════════════════════════════════════

@router.post(
    "/llm/test",
    response_model=LLMTestResponse,
    summary="🧪 اختبار الـ LLM وتحقق من صحة الـ API Key",
    dependencies=[Depends(verify_api_key)],
)
async def test_llm(request: LLMTestRequest):
    """
    أرسل الـ API Key واختبر إذا الـ LLM يعمل بشكل صحيح.
    يُرسل رسالة تجريبية ويُعيد الرد — إذا نجح الـ Key صحيح ✅
    """
    try:
        if request.provider == "openai":
            reply, model_used = await _test_openai(request.api_key, request.model)
        elif request.provider == "groq":
            reply, model_used = await _test_groq(request.api_key, request.model)
        else:
            reply, model_used = await _test_gemini(request.api_key, request.model)

        return LLMTestResponse(
            success=True,
            provider=request.provider,
            model=model_used,
            response=reply,
        )

    except Exception as e:
        return LLMTestResponse(
            success=False,
            provider=request.provider,
            model=request.model or "unknown",
            response="",
            error=str(e),
        )


async def _test_groq(api_key: str, model: str | None) -> tuple[str, str]:
    from openai import AsyncOpenAI
    model = model or "openai/gpt-oss-20b"
    client = AsyncOpenAI(api_key=api_key, base_url="https://api.groq.com/openai/v1")
    response = await client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": TEST_QUESTION}],
        max_tokens=100,
    )
    return response.choices[0].message.content, model


async def _test_openai(api_key: str, model: str | None) -> tuple[str, str]:
    from openai import AsyncOpenAI
    model = model or "gpt-4o"
    client = AsyncOpenAI(api_key=api_key)
    response = await client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": TEST_QUESTION}],
        max_tokens=100,
    )
    return response.choices[0].message.content, model


async def _test_gemini(api_key: str, model: str | None) -> tuple[str, str]:
    import google.generativeai as genai
    model = model or "gemini-1.5-flash"
    genai.configure(api_key=api_key)
    gemini_model = genai.GenerativeModel(model)
    response = await gemini_model.generate_content_async(TEST_QUESTION)
    return response.text, model


# ══════════════════════════════════════════════════════
#   PROMPT — عرض وتعديل الـ System Prompt
# ══════════════════════════════════════════════════════

@router.get(
    "/prompt",
    response_model=PromptResponse,
    summary="📋 عرض الـ System Prompt الحالي",
    dependencies=[Depends(verify_api_key)],
)
async def get_prompt(db: AsyncSession = Depends(get_db)):
    """جلب الـ System Prompt الحالي المستخدم في الـ RAG Pipeline"""
    result = await db.execute(
        select(SystemConfig).where(SystemConfig.key == PROMPT_KEY)
    )
    config = result.scalar_one_or_none()

    if not config:
        # إذا لم يُعدَّل بعد، أرجع الافتراضي
        return PromptResponse(prompt=DEFAULT_PROMPT, updated_at=None)

    return PromptResponse(
        prompt=config.value,
        updated_at=config.updated_at.isoformat() if config.updated_at else None,
    )


@router.put(
    "/prompt",
    response_model=PromptResponse,
    summary="✏️ تعديل الـ System Prompt",
    dependencies=[Depends(verify_api_key)],
)
async def update_prompt(request: PromptUpdateRequest, db: AsyncSession = Depends(get_db)):
    """
    تعديل الـ System Prompt الذي يستخدمه المساعد الذكي.
    التعديل يُطبَّق فوراً على جميع المحادثات القادمة.
    """
    if len(request.prompt.strip()) < 20:
        raise HTTPException(status_code=400, detail="الـ Prompt قصير جداً (20 حرف على الأقل)")

    result = await db.execute(
        select(SystemConfig).where(SystemConfig.key == PROMPT_KEY)
    )
    config = result.scalar_one_or_none()

    if config:
        config.value = request.prompt
    else:
        config = SystemConfig(
            key=PROMPT_KEY,
            value=request.prompt,
            description="System Prompt لمساعد أولياء الأمور",
        )
        db.add(config)

    await db.commit()
    await db.refresh(config)

    return PromptResponse(
        prompt=config.value,
        updated_at=config.updated_at.isoformat() if config.updated_at else None,
    )


@router.delete(
    "/prompt/reset",
    summary="🔄 إعادة الـ Prompt للافتراضي",
    dependencies=[Depends(verify_api_key)],
)
async def reset_prompt(db: AsyncSession = Depends(get_db)):
    """حذف الـ Prompt المخصص والرجوع للـ Prompt الافتراضي"""
    result = await db.execute(
        select(SystemConfig).where(SystemConfig.key == PROMPT_KEY)
    )
    config = result.scalar_one_or_none()
    if config:
        await db.delete(config)
    return {"message": "تم الرجوع للـ Prompt الافتراضي ✅", "prompt": DEFAULT_PROMPT}
