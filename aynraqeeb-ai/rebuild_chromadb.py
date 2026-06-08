import sqlite3
import json
import os
import chromadb
from chromadb.utils.embedding_functions import EmbeddingFunction

import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

PERSIST_DIRECTORY = os.path.join(os.getcwd(), "chroma_db")

class _NoOpEmbeddingFunction(EmbeddingFunction):
    def __call__(self, input):
        return [[0.0] * 384] * len(input)

def rebuild():
    # 1. Initialize ChromaDB
    print("Initializing ChromaDB...")
    client = chromadb.PersistentClient(path=PERSIST_DIRECTORY)
    collection = client.get_or_create_collection(
        name="aynraqeeb_knowledge",
        embedding_function=_NoOpEmbeddingFunction(),
        metadata={"hnsw:space": "cosine"},
    )
    
    # 2. Read from SQLite
    print("Reading from SQLite database...")
    conn = sqlite3.connect("aynraqeeb.db")
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    
    cur.execute("SELECT * FROM chunks")
    rows = cur.fetchall()
    print(f"Found {len(rows)} chunks in database.")
    
    ids = []
    embeddings = []
    documents = []
    metadatas = []
    
    for i, row in enumerate(rows):
        doc_id = str(row["document_id"])
        content = row["content"]
        
        # Parse embedding
        emb_data = row["embedding"]
        if isinstance(emb_data, str):
            emb = json.loads(emb_data)
        elif isinstance(emb_data, bytes):
            emb = json.loads(emb_data.decode("utf-8"))
        else:
            emb = emb_data
            
        print(f"Chunk {i+1} embedding dimension: {len(emb)}")
        
        ids.append(f"rebuilt_{i}_{doc_id}")
        embeddings.append(emb)
        documents.append(content)
        metadatas.append({"doc_id": doc_id})
        
    if ids:
        print("Adding documents to ChromaDB...")
        collection.add(
            ids=ids,
            embeddings=embeddings,
            documents=documents,
            metadatas=metadatas
        )
        print("Documents successfully added to ChromaDB.")
        
    conn.close()

    # 3. Test Query
    print("Running a test query to verify ChromaDB works...")
    dummy_emb = [0.0] * 384
    results = collection.query(
        query_embeddings=[dummy_emb],
        n_results=2
    )
    print("Test Query Results:")
    print(results)
    print("Success! ChromaDB works perfectly without crashing!")

if __name__ == "__main__":
    rebuild()
