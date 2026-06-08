from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.models.session import ChatSession
from app.db.models.config import SystemConfig
from app.services.llm_service import llm_service
from app.services.vector_store import vector_store
from app.config import settings

DEFAULT_PROMPT = """أنت مساعد ذكي لتطبيق عين رقيب (AynRaqeeb) لخدمة أولياء الأمور.
أجب باللغة العربية حصراً وبوضوح."""

PROMPT_KEY = "parent_system_prompt"


class RAGPipeline:
    """نظام RAG المتطور: البحث في ChromaDB + الـ Re-ranking المحلي المجاني"""

    async def _get_system_prompt(self, db: AsyncSession) -> str:
        result = await db.execute(select(SystemConfig).where(SystemConfig.key == PROMPT_KEY))
        config = result.scalar_one_or_none()
        return config.value if config else DEFAULT_PROMPT

    async def search_and_rerank(self, db: AsyncSession, question: str) -> list[str]:
        """
        1. Retrieval: من ChromaDB (باستخدام الـ Embedding المحلي)
        2. Re-ranking: باستخدام الـ Cross-Encoder المحلي
        """
        
        # تحويل السؤال لـ Vector محلياً
        question_embedding = await llm_service.get_embedding(question)

        # البحث في ChromaDB ★
        initial_chunks = await vector_store.search(
            question_embedding=question_embedding,
            limit=settings.RERANK_RESULTS
        )

        if not initial_chunks: return []

        # التصفية والمطابقة النهائية (Re-ranking)
        if settings.USE_RERANKER:
            return await llm_service.rerank(question, initial_chunks)
        
        return initial_chunks[:settings.TOP_K_RESULTS]

    def build_context(self, chunks: list[str]) -> str:
        if not chunks: return "لا توجد معلومات."
        return "\n\n---\n\n".join(chunks)

    async def answer(self, db: AsyncSession, question: str, session_id: str | None, user_id: str, live_context: str | None = None) -> dict:
        relevant_chunks = await self.search_and_rerank(db, question)
        rag_context = self.build_context(relevant_chunks)
        system_prompt = await self._get_system_prompt(db)

        # دمج موقع الباص الحي مع معلومات ChromaDB — الأولوية للبيانات الحية
        if live_context:
            full_context = f"📍 معلومات حية (مباشرة من التطبيق):\n{live_context}\n\n---\n\n📚 معلومات عامة:\n{rag_context}"
        else:
            full_context = rag_context

        full_prompt = f"{system_prompt}\n\nالمعلومات المتاحة:\n{full_context}"
        session = await self._get_or_create_session(db, session_id, user_id)
        
        answer_text = await llm_service.chat(system_prompt=full_prompt, history=session.history or [], question=question)
        
        history = list(session.history or [])
        history.append({"role": "user", "content": question})
        history.append({"role": "assistant", "content": answer_text})
        session.history = history
        await db.commit()
        return {"session_id": str(session.id), "answer": answer_text, "sources_count": len(relevant_chunks)}

    async def answer_stream(self, db: AsyncSession, question: str, session_id: str | None, user_id: str, live_context: str | None = None):
        relevant_chunks = await self.search_and_rerank(db, question)
        rag_context = self.build_context(relevant_chunks)
        system_prompt = await self._get_system_prompt(db)

        # دمج موقع الباص الحي مع معلومات ChromaDB
        if live_context:
            full_context = f"📍 معلومات حية (مباشرة من التطبيق):\n{live_context}\n\n---\n\n📚 معلومات عامة:\n{rag_context}"
        else:
            full_context = rag_context
        
        # استخدام جلسة منفصلة لخصم الجلسة بسرعة لتجنب قفل SQLite أثناء الـ Streaming
        from app.db.database import AsyncSessionLocal
        async with AsyncSessionLocal() as db_session:
            session = await self._get_or_create_session(db_session, session_id, user_id)
            await db_session.commit()
            session_id_val = str(session.id)
            history_copy = list(session.history or [])
        
        full_prompt = f"{system_prompt}\n\nالمعلومات المتاحة:\n{full_context}"
        
        yield f"SESSION_ID:{session_id_val}\n"
        
        full_answer = ""
        async for chunk in llm_service.chat_stream(system_prompt=full_prompt, history=history_copy, question=question):
            full_answer += chunk
            yield chunk

        # حفظ النتيجة في جلسة جديدة سريعة لتجنب قفل القاعدة أثناء الـ streaming الطويل
        from app.db.database import AsyncSessionLocal
        import uuid
        async with AsyncSessionLocal() as db_save:
            result = await db_save.execute(select(ChatSession).where(ChatSession.id == uuid.UUID(session_id_val)))
            session_to_update = result.scalar_one_or_none()
            if session_to_update:
                new_history = list(session_to_update.history or [])
                new_history.append({"role": "user", "content": question})
                new_history.append({"role": "assistant", "content": full_answer})
                session_to_update.history = new_history
                await db_save.commit()

    async def _get_or_create_session(self, db: AsyncSession, session_id: str | None, user_id: str) -> ChatSession:
        if session_id:
            import uuid
            try:
                session_uuid = uuid.UUID(session_id)
                result = await db.execute(select(ChatSession).where(ChatSession.id == session_uuid))
                session = result.scalar_one_or_none()
                if session: return session
            except ValueError:
                pass

        session = ChatSession(user_id=user_id, history=[])
        db.add(session)
        await db.flush()
        return session

rag_pipeline = RAGPipeline()
