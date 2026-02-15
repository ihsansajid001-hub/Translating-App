"""
Speech-to-Text Server using Faster-Whisper
Optimized for CPU inference with streaming support
"""

import os
import io
import base64
import logging
from typing import Optional
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from faster_whisper import WhisperModel
import numpy as np
import soundfile as sf

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="STT Service", version="1.0.0")

# Global model instance
model = None
MODEL_SIZE = os.getenv("WHISPER_MODEL", "base")  # tiny, base, small, medium, large
DEVICE = os.getenv("DEVICE", "cpu")  # cpu or cuda
COMPUTE_TYPE = "int8" if DEVICE == "cpu" else "float16"

class TranscriptionRequest(BaseModel):
    audio: str  # Base64 encoded audio
    language: Optional[str] = None
    model: Optional[str] = None

class TranscriptionResponse(BaseModel):
    text: str
    language: str
    confidence: float
    duration: float

@app.on_event("startup")
async def load_model():
    """Load Whisper model on startup"""
    global model
    try:
        logger.info(f"Loading Whisper model: {MODEL_SIZE} on {DEVICE}")
        model = WhisperModel(
            MODEL_SIZE,
            device=DEVICE,
            compute_type=COMPUTE_TYPE,
            download_root="./models"
        )
        logger.info("✅ Whisper model loaded successfully")
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        raise

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model": MODEL_SIZE,
        "device": DEVICE,
        "model_loaded": model is not None
    }

@app.post("/transcribe", response_model=TranscriptionResponse)
async def transcribe(request: TranscriptionRequest):
    """
    Transcribe audio to text
    
    Args:
        audio: Base64 encoded audio (WAV, MP3, etc.)
        language: Optional language code (e.g., 'en', 'es')
        model: Optional model size override
    
    Returns:
        Transcription text and metadata
    """
    try:
        if model is None:
            raise HTTPException(status_code=503, detail="Model not loaded")

        # Decode base64 audio
        audio_bytes = base64.b64decode(request.audio)
        
        # Load audio
        audio_data, sample_rate = sf.read(io.BytesIO(audio_bytes))
        
        # Convert to mono if stereo
        if len(audio_data.shape) > 1:
            audio_data = audio_data.mean(axis=1)
        
        # Normalize audio
        audio_data = audio_data.astype(np.float32)
        
        # Transcribe
        segments, info = model.transcribe(
            audio_data,
            language=request.language,
            beam_size=5,
            vad_filter=True,  # Voice Activity Detection
            vad_parameters=dict(
                min_silence_duration_ms=500,
                speech_pad_ms=400
            )
        )
        
        # Combine segments
        text = " ".join([segment.text for segment in segments]).strip()
        
        # Calculate average confidence
        segments_list = list(segments)
        avg_confidence = sum(s.avg_logprob for s in segments_list) / len(segments_list) if segments_list else 0.0
        
        logger.info(f"Transcribed: '{text[:50]}...' (lang: {info.language})")
        
        return TranscriptionResponse(
            text=text,
            language=info.language,
            confidence=float(avg_confidence),
            duration=info.duration
        )
        
    except Exception as e:
        logger.error(f"Transcription error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/transcribe-stream")
async def transcribe_stream(request: TranscriptionRequest):
    """
    Streaming transcription for real-time processing
    """
    # TODO: Implement streaming transcription
    # This would use WebSocket for continuous audio streaming
    return {"message": "Streaming not yet implemented"}

@app.get("/models")
async def list_models():
    """List available Whisper models"""
    return {
        "available_models": ["tiny", "base", "small", "medium", "large"],
        "current_model": MODEL_SIZE,
        "device": DEVICE,
        "compute_type": COMPUTE_TYPE
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)
