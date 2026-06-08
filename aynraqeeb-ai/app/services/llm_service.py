from app.config import settings


class LLMService:
    """خدمة موحّدة تدعم Groq (السريع والمجاني) و OpenAI و Gemini"""

    def __init__(self):
        self.provider = settings.LLM_PROVIDER
        self._reranker_model = None
        self._embedding_model = None

    def initialize(self):
        """تحميل الموديلات المحلية مسبقاً لتجنب البطء في أول طلب"""
        if self._embedding_model is None:
            from sentence_transformers import SentenceTransformer
            print("Loading Embedding Model...")
            self._embedding_model = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')
            
        if self._reranker_model is None:
            from sentence_transformers import CrossEncoder
            print("Loading Reranker Model...")
            self._reranker_model = CrossEncoder('cross-encoder/ms-marco-MiniLM-L-6-v2')
        print("All local models loaded.")

    # ─────────────────────────── Local Embeddings (Free 100%) ──────────────────

    async def get_embedding(self, text: str) -> list[float]:
        if self._embedding_model is None:
            from sentence_transformers import SentenceTransformer
            self._embedding_model = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')
        embedding = self._embedding_model.encode(text)
        return embedding.tolist()

    # ─────────────────────────── Chat ───────────────────────────

    async def chat(self, system_prompt: str, history: list[dict], question: str) -> str:
        if self.provider == "openai":
            return await self._openai_chat(system_prompt, history, question)
        elif self.provider == "groq":
            return await self._groq_chat(system_prompt, history, question)
        return await self._gemini_chat(system_prompt, history, question)

    async def chat_stream(self, system_prompt: str, history: list[dict], question: str):
        if self.provider == "openai":
            async for chunk in self._openai_chat_stream(system_prompt, history, question):
                yield chunk
        elif self.provider == "groq":
            async for chunk in self._groq_chat_stream(system_prompt, history, question):
                yield chunk
        else:
            async for chunk in self._gemini_chat_stream(system_prompt, history, question):
                yield chunk

    # --- Groq Logic (New & Fast) ---
    async def _groq_chat(self, system_prompt: str, history: list[dict], question: str) -> str:
        from openai import AsyncOpenAI
        # Groq متوافق تماماً مع OpenAI API
        client = AsyncOpenAI(api_key=settings.GROQ_API_KEY, base_url="https://api.groq.com/openai/v1")
        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(history[-6:])
        messages.append({"role": "user", "content": question})
        response = await client.chat.completions.create(model=settings.GROQ_CHAT_MODEL, messages=messages, temperature=0.3)
        return response.choices[0].message.content

    async def _groq_chat_stream(self, system_prompt: str, history: list[dict], question: str):
        from openai import AsyncOpenAI
        client = AsyncOpenAI(api_key=settings.GROQ_API_KEY, base_url="https://api.groq.com/openai/v1")
        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(history[-6:])
        messages.append({"role": "user", "content": question})
        response = await client.chat.completions.create(model=settings.GROQ_CHAT_MODEL, messages=messages, stream=True, temperature=0.3)
        async for chunk in response:
            if chunk.choices and chunk.choices[0].delta.content:
                yield chunk.choices[0].delta.content

    # --- OpenAI & Gemini (Existing) ---
    async def _openai_chat(self, system_prompt: str, history: list[dict], question: str) -> str:
        from openai import AsyncOpenAI
        client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(history[-6:])
        messages.append({"role": "user", "content": question})
        response = await client.chat.completions.create(model=settings.OPENAI_CHAT_MODEL, messages=messages, temperature=0.3)
        return response.choices[0].message.content

    async def _openai_chat_stream(self, system_prompt: str, history: list[dict], question: str):
        from openai import AsyncOpenAI
        client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(history[-6:])
        messages.append({"role": "user", "content": question})
        response = await client.chat.completions.create(model=settings.OPENAI_CHAT_MODEL, messages=messages, stream=True, temperature=0.3)
        async for chunk in response:
            if chunk.choices and chunk.choices[0].delta.content:
                yield chunk.choices[0].delta.content

    async def _gemini_chat_stream(self, system_prompt: str, history: list[dict], question: str):
        import google.generativeai as genai
        genai.configure(api_key=settings.GEMINI_API_KEY)
        model = genai.GenerativeModel(model_name=settings.GEMINI_CHAT_MODEL, system_instruction=system_prompt)
        gemini_history = []
        for msg in history[-6:]:
            role = "user" if msg["role"] == "user" else "model"
            gemini_history.append({"role": role, "parts": [msg["content"]]})
        chat = model.start_chat(history=gemini_history)
        response = await chat.send_message_async(question, stream=True)
        async for chunk in response:
            if chunk.text:
                yield chunk.text

    # ─────────────────────────── Re-ranking (مجاني بموديل محلي) ──────────────────

    async def rerank(self, question: str, chunks: list[str]) -> list[str]:
        if not chunks: return []
        if self._reranker_model is None:
            from sentence_transformers import CrossEncoder
            self._reranker_model = CrossEncoder('cross-encoder/ms-marco-MiniLM-L-6-v2')
        pairs = [[question, chunk] for chunk in chunks]
        scores = self._reranker_model.predict(pairs)
        combined = list(zip(chunks, scores))
        combined.sort(key=lambda x: x[1], reverse=True)
        reranked_chunks = [item[0] for item in combined]
        return reranked_chunks[:settings.TOP_K_RESULTS]


llm_service = LLMService()
