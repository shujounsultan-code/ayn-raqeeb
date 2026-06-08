import uuid
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.security import verify_api_key
from app.db.database import get_db
from app.db.models.document import Document
from app.db.models.chunk import Chunk
from app.schemas.document import DocumentResponse, DocumentUploadResponse, ManualQARequest
from app.services.document_processor import document_processor
from app.services.llm_service import llm_service
from app.services.vector_store import vector_store

router = APIRouter(prefix="/documents", tags=["📄 الوثائق"])

ALLOWED_TYPES = {
    "application/pdf": "pdf",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
    "text/plain": "txt",
}


@router.post(
    "/upload",
    response_model=DocumentUploadResponse,
    summary="رفع وثيقة جديدة",
    dependencies=[Depends(verify_api_key)],
)
async def upload_document(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
):
    """رفع ملف PDF أو Word أو TXT — يُعالَج تلقائياً ويُضاف للنظام"""

    # التحقق من نوع الملف
    file_type = ALLOWED_TYPES.get(file.content_type)
    if not file_type:
        raise HTTPException(
            status_code=400,
            detail="نوع الملف غير مدعوم. المقبول: PDF, Word, TXT",
        )

    # قراءة الملف
    file_bytes = await file.read()

    # إنشاء سجل الوثيقة
    doc = Document(name=file.filename, file_type=file_type, status="processing")
    db.add(doc)
    await db.flush()
    doc_id = doc.id
    await db.commit()

    # معالجة في الخلفية (لا تُبطئ الـ response)
    background_tasks.add_task(
        _process_document, doc_id, file_bytes, file_type
    )

    return DocumentUploadResponse(
        id=str(doc_id),
        name=file.filename,
        message="تم رفع الملف وجارٍ معالجته...",
    )


async def _process_document(doc_id: uuid.UUID, file_bytes: bytes, file_type: str):
    """معالجة الوثيقة في الخلفية: استخراج → تقطيع → تحويل لـ Vectors → حفظ"""
    from app.db.database import AsyncSessionLocal

    async with AsyncSessionLocal() as db:
        try:
            # استخراج النص
            text = document_processor.extract_text(file_bytes, file_type)

            # تقطيع النص
            chunks = document_processor.chunk_text(text)

            # تحويل كل الـ chunks لـ Vectors دفعة واحدة
            embeddings = []
            for chunk_content in chunks:
                embedding = await llm_service.get_embedding(chunk_content)
                embeddings.append(embedding)

            # حفظ في ChromaDB ★
            await vector_store.add_documents(chunks=chunks, embeddings=embeddings, doc_id=doc_id)

            # تحديث حالة الوثيقة في PostgreSQL
            result = await db.execute(select(Document).where(Document.id == doc_id))
            doc = result.scalar_one()
            doc.status = "ready"
            await db.commit()

        except Exception as e:
            # في حالة الخطأ
            result = await db.execute(select(Document).where(Document.id == doc_id))
            doc = result.scalar_one_or_none()
            if doc:
                doc.status = "failed"
                await db.commit()


@router.get(
    "/",
    response_model=list[DocumentResponse],
    summary="قائمة الوثائق المرفوعة",
    dependencies=[Depends(verify_api_key)],
)
async def list_documents(db: AsyncSession = Depends(get_db)):
    """جلب قائمة جميع الوثائق وحالة معالجتها"""
    result = await db.execute(select(Document).order_by(Document.created_at.desc()))
    docs = result.scalars().all()
    return [
        DocumentResponse(
            id=str(d.id), name=d.name, file_type=d.file_type, status=d.status
        )
        for d in docs
    ]


@router.delete(
    "/{doc_id}",
    summary="حذف وثيقة",
    dependencies=[Depends(verify_api_key)],
)
async def delete_document(doc_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """حذف وثيقة وجميع الـ chunks المرتبطة بها من SQLite و ChromaDB"""
    result = await db.execute(select(Document).where(Document.id == doc_id))
    doc = result.scalar_one_or_none()

    if not doc:
        raise HTTPException(status_code=404, detail="الوثيقة غير موجودة")

    # ✅ مسح الـ Vectors من ChromaDB أولاً
    await vector_store.delete_by_doc_id(doc_id)

    await db.delete(doc)
    return {"message": f"تم حذف الوثيقة '{doc.name}' بنجاح"}


@router.post(
    "/manual-qa",
    summary="إضافة سؤال وجواب يدوياً",
    dependencies=[Depends(verify_api_key)],
)
async def add_manual_qa(request: ManualQARequest, db: AsyncSession = Depends(get_db)):
    """إضافة معلومة بشكل مباشر (سؤال وجواب) لضمان دقة الإجابة عليها"""
    
    # 1. تجهيز النص والـ Vector أولاً (خارج الترانزاكشن لتجنب Lock)
    combined_text = f"سؤال: {request.question}\nإجابة: {request.answer}"
    embedding = await llm_service.get_embedding(combined_text)
    
    # 2. إنشاء وثيقة وهمية
    doc_id = uuid.uuid4()
    doc_name = f"Q&A: {request.question[:30]}..."
    doc = Document(id=doc_id, name=doc_name, file_type="manual", status="ready")
    
    # 3. إنشاء الـ Chunk المرتبط
    chunk = Chunk(
        document_id=doc_id,
        content=combined_text,
        chunk_index=0,
        embedding=embedding
    )
    
    # 4. الحفظ في قاعدة البيانات
    db.add(doc)
    db.add(chunk)
    await db.flush()

    # ✅ 5. الحفظ في ChromaDB حتى يظهر في نتائج البحث
    await vector_store.add_documents(
        chunks=[combined_text],
        embeddings=[embedding],
        doc_id=doc_id
    )
    
    return {"message": "تمت إضافة المعلومة بنجاح وتدريب النظام عليها ✅"}
