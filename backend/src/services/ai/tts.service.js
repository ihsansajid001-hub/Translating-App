import axios from 'axios';
import { config } from '../../config/index.js';
import { logger } from '../../utils/logger.js';
import { redis } from '../redis.js';
import crypto from 'crypto';

/**
 * Synthesize speech from text
 * Supports: Local Piper TTS, Edge TTS, Coqui TTS, or hybrid mode
 * Includes caching for common phrases
 */
export const synthesizeSpeech = async (text, language, voice = null) => {
  const startTime = Date.now();
  
  try {
    // Check cache first
    const cacheKey = generateCacheKey(text, language, voice);
    const cached = await redis.get(cacheKey);
    
    if (cached) {
      logger.info('TTS cache hit');
      return Buffer.from(cached, 'base64');
    }

    let audioBuffer;

    if (config.ai.ttsEngine === 'piper') {
      audioBuffer = await synthesizeWithPiper(text, language, voice);
    } else if (config.ai.ttsEngine === 'edge') {
      audioBuffer = await synthesizeWithEdge(text, language, voice);
    } else if (config.ai.ttsEngine === 'coqui') {
      audioBuffer = await synthesizeWithCoqui(text, language, voice);
    } else {
      // Default to Piper (fastest, free)
      audioBuffer = await synthesizeWithPiper(text, language, voice);
    }

    // Cache the audio (only for short texts to save memory)
    if (text.length < 100) {
      await redis.setex(
        cacheKey,
        config.translationCacheTTL,
        audioBuffer.toString('base64')
      );
    }

    const latency = Date.now() - startTime;
    logger.info(`TTS completed in ${latency}ms for text: "${text.substring(0, 30)}..."`);

    return audioBuffer;
  } catch (error) {
    logger.error('TTS error:', error);
    throw new Error('Text-to-speech failed');
  }
};

/**
 * Synthesize using local Piper TTS (BEST for FREE - fast, CPU-only)
 */
const synthesizeWithPiper = async (text, language, voice) => {
  try {
    const response = await axios.post(
      `${config.ai.ttsServiceUrl}/synthesize`,
      {
        text,
        language,
        voice: voice || getDefaultVoice(language),
        format: 'wav'
      },
      {
        timeout: 10000,
        headers: { 'Content-Type': 'application/json' },
        responseType: 'arraybuffer'
      }
    );

    return Buffer.from(response.data);
  } catch (error) {
    logger.error('Piper TTS error:', error.message);
    throw error;
  }
};

/**
 * Synthesize using Edge TTS (Microsoft's FREE API - unofficial but works)
 */
const synthesizeWithEdge = async (text, language, voice) => {
  try {
    const edgeVoice = getEdgeVoice(language);
    
    const response = await axios.post(
      `${config.ai.ttsServiceUrl}/edge-tts`,
      {
        text,
        voice: edgeVoice
      },
      {
        timeout: 10000,
        responseType: 'arraybuffer'
      }
    );

    return Buffer.from(response.data);
  } catch (error) {
    logger.error('Edge TTS error:', error.message);
    throw error;
  }
};

/**
 * Synthesize using Coqui TTS (self-hosted, good quality)
 */
const synthesizeWithCoqui = async (text, language, voice) => {
  try {
    const response = await axios.post(
      `${config.ai.ttsServiceUrl}/coqui-tts`,
      {
        text,
        language,
        speaker_id: voice || 'default'
      },
      {
        timeout: 15000,
        responseType: 'arraybuffer'
      }
    );

    return Buffer.from(response.data);
  } catch (error) {
    logger.error('Coqui TTS error:', error.message);
    throw error;
  }
};

/**
 * Generate cache key for TTS
 */
const generateCacheKey = (text, language, voice) => {
  const hash = crypto
    .createHash('md5')
    .update(`${text}:${language}:${voice || 'default'}`)
    .digest('hex');
  return `tts:${hash}`;
};

/**
 * Get default voice for language (Piper voices)
 */
const getDefaultVoice = (language) => {
  const voices = {
    'en': 'en_US-lessac-medium',
    'es': 'es_ES-davefx-medium',
    'fr': 'fr_FR-siwis-medium',
    'de': 'de_DE-thorsten-medium',
    'it': 'it_IT-riccardo-medium',
    'pt': 'pt_BR-faber-medium',
    'ru': 'ru_RU-ruslan-medium',
    'ar': 'ar_JO-kareem-medium',
    'zh': 'zh_CN-huayan-medium',
    'ja': 'ja_JP-hikari-medium',
    'ko': 'ko_KR-kss-medium',
    'hi': 'hi_IN-kavya-medium',
    'tr': 'tr_TR-dfki-medium',
    'nl': 'nl_NL-mls-medium',
    'pl': 'pl_PL-mls-medium'
  };
  
  return voices[language] || voices['en'];
};

/**
 * Get Edge TTS voice for language
 */
const getEdgeVoice = (language) => {
  const voices = {
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
  };
  
  return voices[language] || voices['en'];
};

/**
 * Stream TTS audio (for long texts)
 */
export const streamSpeech = async function* (text, language, voice = null) {
  // Split text into sentences
  const sentences = text.match(/[^.!?]+[.!?]+/g) || [text];
  
  for (const sentence of sentences) {
    const audioBuffer = await synthesizeSpeech(sentence.trim(), language, voice);
    yield audioBuffer;
  }
};
