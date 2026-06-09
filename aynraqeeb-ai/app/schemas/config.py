from pydantic import BaseModel
from typing import Literal, Optional

class LLMTestRequest(BaseModel):
    provider: Literal["openai"]
    api_key: str
    model: str
    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "summary": "اختبار OpenAI",
                    "value": {
                        "provider": "openai",
                        "api_key": "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",
                        "model": "gpt-4o",
                    },
                }
            ]
        }
    }
