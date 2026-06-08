import chromadb
from chromadb.utils.embedding_functions import EmbeddingFunction
import uuid
import os

# المسار الذي سيتم حفظ البيانات فيه
PERSIST_DIRECTORY = os.path.join(os.getcwd(), "chroma_db")


class _NoOpEmbeddingFunction(EmbeddingFunction):
    """
    Embedding function وهمية — نستخدمها فقط لتجنب تحميل onnxruntime
    لأننا نمرر الـ embeddings يدوياً من sentence_transformers.
    """
    def __call__(self, input):  # noqa: A002
        return [[0.0] * 384] * len(input)


class VectorStore:
    """إدارة مخزن الـ Vectors باستخدام ChromaDB (خفيف ومجاني)"""

    def __init__(self):
        self.client = chromadb.PersistentClient(path=PERSIST_DIRECTORY)
        # إنشاء أو جلب الـ Collection مع embedding function وهمية
        # (الـ embeddings الحقيقية تأتي من sentence_transformers وتُمرَّر يدوياً)
        self.collection = self.client.get_or_create_collection(
            name="aynraqeeb_knowledge",
            embedding_function=_NoOpEmbeddingFunction(),
            metadata={"hnsw:space": "cosine"},
        )

    async def add_documents(self, chunks: list[str], embeddings: list[list[float]], doc_id: str):
        """إضافة القطع والـ Vectors للـ ChromaDB"""
        ids = [str(uuid.uuid4()) for _ in chunks]
        metadatas = [{"doc_id": str(doc_id)} for _ in chunks]
        
        self.collection.add(
            ids=ids,
            embeddings=embeddings,
            documents=chunks,
            metadatas=metadatas
        )

    async def search(self, question_embedding: list[float], limit: int = 5) -> list[str]:
        """البحث عن أقرب النصوص للسؤال"""
        results = self.collection.query(
            query_embeddings=[question_embedding],
            n_results=limit
        )
        
        # النتائج تكون في ['documents'][0]
        return results['documents'][0] if results['documents'] else []

    async def delete_by_doc_id(self, doc_id: str):
        """حذف كل البيانات المرتبطة بوثيقة معينة"""
        self.collection.delete(
            where={"doc_id": str(doc_id)}
        )

vector_store = VectorStore()
