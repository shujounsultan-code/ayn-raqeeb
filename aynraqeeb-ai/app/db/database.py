from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import event
from app.config import settings


class Base(DeclarativeBase):
    pass


# محرك SQLite يدعم الاتصالات المتعددة عبر الخيط (thread) للأداء السلس
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    connect_args={
        "check_same_thread": False,
        "timeout": 30  # زيادة مهلة الانتظار لفك قفل قاعدة البيانات
    } 
)


# تفعيل وضع WAL (Write-Ahead Logging) لتحسين الأداء المتزامن في SQLite
@event.listens_for(engine.sync_engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA journal_mode=WAL")
    cursor.execute("PRAGMA synchronous=NORMAL")
    cursor.close()


AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def get_db():
    """Dependency لاستخدامه في كل endpoint"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


async def init_db():
    """إنشاء جداول الميتا-داتا (SQLite)"""
    # استيراد النماذج المطلوبة فقط للميتا-داتا
    from app.db.models import document, session, config, chunk

    async with engine.begin() as conn:
        # SQLite لا يحتاج CREATE EXTENSION
        await conn.run_sync(Base.metadata.create_all)
