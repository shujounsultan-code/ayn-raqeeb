from pydantic import BaseModel
from typing import Optional
import uuid


class DocumentResponse(BaseModel):
    id: str
    name: str
    file_type: str
    status: str

    model_config = {"from_attributes": True}


class DocumentUploadResponse(BaseModel):
    id: str
    name: str
    message: str


class ManualQARequest(BaseModel):
    question: str
    answer: str
