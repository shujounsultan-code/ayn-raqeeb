from fastapi import APIRouter
from app.api.v1.endpoints import chat, documents, config

router = APIRouter(prefix="/api/v1")

router.include_router(chat.router)
router.include_router(documents.router)
router.include_router(config.router)
