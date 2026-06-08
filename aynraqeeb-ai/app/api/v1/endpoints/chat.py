import uuid
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.security import verify_api_key
from app.db.database import get_db
from app.db.models.session import ChatSession
from app.schemas.chat import ChatRequest, ChatResponse, SessionHistoryResponse
from app.services.rag_pipeline import rag_pipeline

router = APIRouter(prefix="/ai", tags=["💬 المحادثة الذكية"])


@router.post(
    "/chat",
    response_model=ChatResponse,
    summary="سؤال ولي الأمر للمساعد الذكي",
    dependencies=[Depends(verify_api_key)],
)
async def chat(request: ChatRequest, db: AsyncSession = Depends(get_db)):
    """
    ★ الـ Endpoint الرئيسي — ولي الأمر يسأل سؤالاً ويحصل على إجابة ذكية
    مبنية على وثائق تطبيق عين رقيب.
    """
    try:
        result = await rag_pipeline.answer(
            db=db,
            question=request.message,
            session_id=request.session_id,
            user_id=request.user_id,
            live_context=request.live_context,
        )
        return ChatResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في معالجة السؤال: {str(e)}")


@router.post(
    "/chat/stream",
    summary="سؤال ولي الأمر (Streaming)",
    dependencies=[Depends(verify_api_key)],
)
async def chat_stream(request: ChatRequest, db: AsyncSession = Depends(get_db)):
    """
    ★ النسخة المتطورة من الـ API — تظهر الإجابة كلمة بكلمة (Streaming)
    لتحسين تجربة ولي الأمر وجعلها أكثر حيوية.
    """
    return StreamingResponse(
        rag_pipeline.answer_stream(
            db=db,
            question=request.message,
            session_id=request.session_id,
            user_id=request.user_id,
            live_context=request.live_context,
        ),
        media_type="text/event-stream",
    )


@router.get(
    "/chat/history/{session_id}",
    response_model=SessionHistoryResponse,
    summary="سجل محادثة جلسة معينة",
    dependencies=[Depends(verify_api_key)],
)
async def get_history(session_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """جلب سجل المحادثة الكاملة لجلسة معينة"""
    result = await db.execute(select(ChatSession).where(ChatSession.id == session_id))
    session = result.scalar_one_or_none()

    if not session:
        raise HTTPException(status_code=404, detail="الجلسة غير موجودة")

    return SessionHistoryResponse(
        session_id=str(session.id),
        user_id=session.user_id,
        history=session.history or [],
    )


@router.delete(
    "/session/{session_id}",
    summary="حذف جلسة محادثة",
    dependencies=[Depends(verify_api_key)],
)
async def delete_session(session_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """حذف جلسة محادثة ومسح سجلها"""
    result = await db.execute(select(ChatSession).where(ChatSession.id == session_id))
    session = result.scalar_one_or_none()

    if not session:
        raise HTTPException(status_code=404, detail="الجلسة غير موجودة")

    await db.delete(session)
    return {"message": "تم حذف الجلسة بنجاح"}
