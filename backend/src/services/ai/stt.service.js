import axios from 'axios';
import { config } from '../../config/index.js';
import { logger } from '../../utils/logger.js';
import { redis } from '../redis.js';

/**
 * Transcribe audio to text using Speech-to-Text service
 * Supports: Local Whisper.cpp, Hugging Face API, or hybrid mode
 */
export const transcribeAudio = async (audioData, language) => {
  const startTime = Date.now();
  
  try {
    let transcription;

    if (config.ai.mode === 'huggingface') {
      transcription = await transcribeWithHuggingFace(audioData, language);
    } else if (config.ai.mode === 'local') {
      transcription = await transcribeWithLocal(audioData, language);
    } else {
      // Hybrid: try local first, fallback to HF
      try {
        transcription = await transcribeWithLocal(audioData, language);
      } catch (error) {
        logger.warn('Local STT failed, falling back to Hugging Face');
        transcription = await transcribeWithHuggingFace(audioData, language);
      }
    }

    const latency = Date.now() - startTime;
    logger.info(`STT completed in ${latency}ms: "${transcription.substring(0, 50)}..."`);

    return transcription;
  } catch (error) {
    logger.error('STT error:', error);
    throw new Error('Speech-to-text failed');
  }
};

/**
 * Transcribe using local Whisper.cpp service
 */
const transcribeWithLocal = async (audioData, language) => {
  try {
    const response = await axios.post(
      `${config.ai.sttServiceUrl}/transcribe`,
      {
        audio: audioData,
        language,
        model: config.ai.whisperModel
      },
      {
        timeout: 10000,
        headers: { 'Content-Type': 'application/json' }
      }
    );

    return response.data.text;
  } catch (error) {
    logger.error('Local STT error:', error.message);
    throw error;
  }
};

/**
 * Transcribe using Hugging Face Inference API (FREE tier)
 */
const transcribeWithHuggingFace = async (audioData, language) => {
  try {
    if (!config.ai.huggingfaceApiKey) {
      throw new Error('Hugging Face API key not configured');
    }

    // Use Whisper model on Hugging Face
    const response = await axios.post(
      'https://api-inference.huggingface.co/models/openai/whisper-base',
      audioData,
      {
        headers: {
          'Authorization': `Bearer ${config.ai.huggingfaceApiKey}`,
          'Content-Type': 'audio/wav'
        },
        timeout: 15000
      }
    );

    return response.data.text;
  } catch (error) {
    logger.error('Hugging Face STT error:', error.message);
    throw error;
  }
};

/**
 * Detect voice activity in audio chunk
 * Returns true if speech is detected
 */
export const detectVoiceActivity = async (audioData) => {
  try {
    // Simple energy-based VAD
    const buffer = Buffer.from(audioData, 'base64');
    const samples = new Int16Array(buffer.buffer);
    
    // Calculate RMS energy
    let sum = 0;
    for (let i = 0; i < samples.length; i++) {
      sum += samples[i] * samples[i];
    }
    const rms = Math.sqrt(sum / samples.length);
    
    // Threshold for voice activity (adjust based on testing)
    const threshold = 500;
    
    return rms > threshold;
  } catch (error) {
    logger.error('VAD error:', error);
    return true; // Default to processing if VAD fails
  }
};
