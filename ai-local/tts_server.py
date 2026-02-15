"""
Text-to-Speech Server using Piper TTS and Edge TTS
Optimized for quality and speed
"""

import os
import io
import base64
import logging
import asyncio
from typing import Optional
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import edge_tts
import numpy as np

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="TTS Service", version="1.0.0")

TTS_ENGINE = os.getenv("TTS_ENGINE", "edge")  # piper or edge

# Voice mapping for Edge TTS
EDGE_VOICES = {
    'en': 'en-US-AriaNeural',
    'es': 'es-ES-ElviraNeural',
    'fr': 'fr-FR-DeniseNeural',
    'de': 'de-DE-KatjaNeural',
    'it': 'it-IT-ElsaNeural',
    'pt': 'pt-BR-FranciscaNeural',
    'ru': 'ru-RU-SvetlanaNeural',
    'ar': 'ar-SA-ZariyahNeural',
    'zh': 'zh-CN-XiaoxiaoNeural',
    'ja': 'ja-JP-NanamiNeural',
    'ko': 'ko-KR-SunHiNeural',
    'hi': 'hi-IN-SwaraNeural',
    'tr': 'tr-TR-EmelNeural',
    'nl': 'nl-NL-ColetteNeural',
    'pl': 'pl-PL-ZofiaNeural'
}

class TTSRequest(BaseModel):
    text: str
    language: str
    voice: Optional[str] = None
    format: Optional[str] = "wav"
    speed: Optional[float] = 1.0

class TTSResponse(BaseModel):
    audio: str  # Base64 encoded audio
    format: str
    duration: float

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "engine": TTS_ENGINE,
        "supported_languages": list(EDGE_VOICES.keys())
    }

@app.post("/synthesize", response_model=TTSResponse)
async def synthesize(request: TTSRequest):
    """
    Synthesize speech from text
    
    Args:
        text: Text to synthesize
        language: Language code (ISO 639-1)
        voice: Optional voice name
        format: Audio format (wav, mp3)
        speed: Speech speed (0.5 - 2.0)
    
    Returns:
        Base64 encoded audio
    """
    try:
        if TTS_ENGINE == "edge":
            audio_data = await synthesize_with_edge(
                request.text,
                request.language,
                request.voice,
                request.speed
            )
        else:
            audio_data = await synthesize_with_piper(
                request.text,
                request.language,
                request.voice
            )
        
        # Encode to base64
        audio_base64 = base64.b64encode(audio_data).decode('utf-8')
        
        # Estimate duration (rough calculation)
        duration = len(request.text.split()) * 0.5  # ~0.5 seconds per word
        
        logger.info(f"Synthesized speech for: '{request.text[:30]}...' (lang: {request.language})")
        
        return TTSResponse(
            audio=audio_base64,
            format=request.format,
            duration=duration
        )
        
    except Exception as e:
        logger.error(f"TTS error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

async def synthesize_with_edge(text: str, language: str, voice: Optional[str], speed: float):
    """
    Synthesize using Edge TTS (Microsoft's free API)
    BEST OPTION for FREE - high quality, fast, no setup needed
    """
    try:
        # Get voice for language
        voice_name = voice or EDGE_VOICES.get(language, EDGE_VOICES['en'])
        
        # Create TTS instance
        communicate = edge_tts.Communicate(
            text,
            voice_name,
            rate=f"{int((speed - 1) * 100):+d}%"  # Convert speed to percentage
        )
        
        # Generate audio
        audio_data = b""
        async for chunk in communicate.stream():
            if chunk["type"] == "audio":
                audio_data += chunk["data"]
        
        return audio_data
        
    except Exception as e:
        logger.error(f"Edge TTS error: {e}")
        raise

async def synthesize_with_piper(text: str, language: str, voice: Optional[str]):
    """
    Synthesize using Piper TTS (local, CPU-only)
    Good quality, fast, but requires model download
    """
    try:
        # TODO: Implement Piper TTS
        # This requires downloading Piper models first
        # For now, fallback to Edge TTS
        return await synthesize_with_edge(text, language, voice, 1.0)
        
    except Exception as e:
        logger.error(f"Piper TTS error: {e}")
        raise

@app.post("/edge-tts")
async def edge_tts_endpoint(request: TTSRequest):
    """Direct Edge TTS endpoint"""
    return await synthesize(request)

@app.get("/voices")
async def list_voices():
    """List available voices"""
    return {
        "engine": TTS_ENGINE,
        "voices": EDGE_VOICES,
        "supported_languages": list(EDGE_VOICES.keys())
    }

@app.get("/voices/{language}")
async def get_voice_for_language(language: str):
    """Get voice for specific language"""
    voice = EDGE_VOICES.get(language)
    if not voice:
        raise HTTPException(status_code=404, detail="Language not supported")
    
    return {
        "language": language,
        "voice": voice
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5002)
