"""
Translation Server using NLLB-200
Supports 200 languages with high quality
"""

import os
import logging
from typing import Optional
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM, pipeline
import torch

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Translation Service", version="1.0.0")

# Global model instances
tokenizer = None
model = None
translator = None

MODEL_NAME = os.getenv("NLLB_MODEL", "facebook/nllb-200-distilled-600M")
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# Language code mapping (ISO 639-1 to NLLB format)
LANG_MAP = {
    'en': 'eng_Latn', 'es': 'spa_Latn', 'fr': 'fra_Latn', 'de': 'deu_Latn',
    'it': 'ita_Latn', 'pt': 'por_Latn', 'ru': 'rus_Cyrl', 'ar': 'arb_Arab',
    'zh': 'zho_Hans', 'ja': 'jpn_Jpan', 'ko': 'kor_Hang', 'hi': 'hin_Deva',
    'tr': 'tur_Latn', 'nl': 'nld_Latn', 'pl': 'pol_Latn'
}

class TranslationRequest(BaseModel):
    text: str
    source_language: str
    target_language: str
    model: Optional[str] = None

class TranslationResponse(BaseModel):
    translation: str
    source_language: str
    target_language: str
    confidence: Optional[float] = None

@app.on_event("startup")
async def load_model():
    """Load NLLB model on startup"""
    global tokenizer, model, translator
    try:
        logger.info(f"Loading NLLB model: {MODEL_NAME} on {DEVICE}")
        
        tokenizer = AutoTokenizer.from_pretrained(
            MODEL_NAME,
            cache_dir="./models"
        )
        
        model = AutoModelForSeq2SeqLM.from_pretrained(
            MODEL_NAME,
            cache_dir="./models"
        ).to(DEVICE)
        
        # Create translation pipeline
        translator = pipeline(
            "translation",
            model=model,
            tokenizer=tokenizer,
            device=0 if DEVICE == "cuda" else -1
        )
        
        logger.info("✅ NLLB model loaded successfully")
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        raise

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model": MODEL_NAME,
        "device": DEVICE,
        "model_loaded": model is not None
    }

@app.post("/translate", response_model=TranslationResponse)
async def translate(request: TranslationRequest):
    """
    Translate text between languages
    
    Args:
        text: Text to translate
        source_language: Source language code (ISO 639-1)
        target_language: Target language code (ISO 639-1)
    
    Returns:
        Translated text
    """
    try:
        if model is None or tokenizer is None:
            raise HTTPException(status_code=503, detail="Model not loaded")

        # Map language codes
        src_lang = LANG_MAP.get(request.source_language, request.source_language)
        tgt_lang = LANG_MAP.get(request.target_language, request.target_language)
        
        # Set source language
        tokenizer.src_lang = src_lang
        
        # Tokenize
        inputs = tokenizer(
            request.text,
            return_tensors="pt",
            padding=True,
            truncation=True,
            max_length=512
        ).to(DEVICE)
        
        # Generate translation
        translated_tokens = model.generate(
            **inputs,
            forced_bos_token_id=tokenizer.lang_code_to_id[tgt_lang],
            max_length=512,
            num_beams=5,
            early_stopping=True
        )
        
        # Decode
        translation = tokenizer.batch_decode(
            translated_tokens,
            skip_special_tokens=True
        )[0]
        
        logger.info(f"Translated ({request.source_language}→{request.target_language}): '{request.text[:30]}...' → '{translation[:30]}...'")
        
        return TranslationResponse(
            translation=translation,
            source_language=request.source_language,
            target_language=request.target_language
        )
        
    except Exception as e:
        logger.error(f"Translation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/batch-translate")
async def batch_translate(texts: list[str], source_language: str, target_language: str):
    """
    Batch translate multiple texts
    """
    try:
        translations = []
        for text in texts:
            result = await translate(TranslationRequest(
                text=text,
                source_language=source_language,
                target_language=target_language
            ))
            translations.append(result.translation)
        
        return {"translations": translations}
        
    except Exception as e:
        logger.error(f"Batch translation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/languages")
async def list_languages():
    """List supported languages"""
    return {
        "supported_languages": list(LANG_MAP.keys()),
        "total_languages": len(LANG_MAP)
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5001)
