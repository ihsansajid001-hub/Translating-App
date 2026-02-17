import axios from 'axios';
import { config } from '../../config/index.js';
import { logger } from '../../utils/logger.js';
import { redis } from '../redis.js';
import crypto from 'crypto';

/**
 * Translate text between languages
 * Supports: Local NLLB, Hugging Face API, or hybrid mode
 * Includes caching for common translations
 */
export const translateText = async (text, sourceLanguage, targetLanguage) => {
  const startTime = Date.now();
  
  try {
    // Check cache first
    const cacheKey = generateCacheKey(text, sourceLanguage, targetLanguage);
    const cached = await redis.get(cacheKey);
    
    if (cached) {
      logger.info('Translation cache hit');
      return cached;
    }

    let translation;

    if (config.ai.mode === 'huggingface') {
      translation = await translateWithHuggingFace(text, sourceLanguage, targetLanguage);
    } else if (config.ai.mode === 'local') {
      translation = await translateWithLocal(text, sourceLanguage, targetLanguage);
    } else {
      // Hybrid: try local first, fallback to HF
      try {
        translation = await translateWithLocal(text, sourceLanguage, targetLanguage);
      } catch (error) {
        logger.warn('Local translation failed, falling back to Hugging Face');
        translation = await translateWithHuggingFace(text, sourceLanguage, targetLanguage);
      }
    }

    // Cache the translation
    await redis.setex(cacheKey, config.translationCacheTTL, translation);

    const latency = Date.now() - startTime;
    logger.info(`Translation completed in ${latency}ms: "${text}" -> "${translation}"`);

    return translation;
  } catch (error) {
    logger.error('Translation error:', error);
    throw new Error('Translation failed');
  }
};

/**
 * Translate using local NLLB service
 */
const translateWithLocal = async (text, sourceLanguage, targetLanguage) => {
  try {
    const response = await axios.post(
      `${config.ai.translationServiceUrl}/translate`,
      {
        text,
        source_language: sourceLanguage,
        target_language: targetLanguage,
        model: config.ai.nllbModel
      },
      {
        timeout: 10000,
        headers: { 'Content-Type': 'application/json' }
      }
    );

    return response.data.translation;
  } catch (error) {
    logger.error('Local translation error:', error.message);
    throw error;
  }
};

/**
 * Translate using Hugging Face Inference API (FREE tier)
 */
const translateWithHuggingFace = async (text, sourceLanguage, targetLanguage) => {
  try {
    if (!config.ai.huggingfaceApiKey) {
      throw new Error('Hugging Face API key not configured');
    }

    // Map language codes to NLLB format (e.g., 'en' -> 'eng_Latn')
    const sourceLang = mapLanguageCode(sourceLanguage);
    const targetLang = mapLanguageCode(targetLanguage);

    const response = await axios.post(
      'https://api-inference.huggingface.co/models/facebook/nllb-200-distilled-600M',
      {
        inputs: text,
        parameters: {
          src_lang: sourceLang,
          tgt_lang: targetLang
        }
      },
      {
        headers: {
          'Authorization': `Bearer ${config.ai.huggingfaceApiKey}`,
          'Content-Type': 'application/json'
        },
        timeout: 15000
      }
    );

    return response.data[0].translation_text;
  } catch (error) {
    logger.error('Hugging Face translation error:', error.message);
    throw error;
  }
};

/**
 * Generate cache key for translation
 */
const generateCacheKey = (text, sourceLang, targetLang) => {
  const hash = crypto
    .createHash('md5')
    .update(`${text}:${sourceLang}:${targetLang}`)
    .digest('hex');
  return `translation:${hash}`;
};

/**
 * Map ISO 639-1 codes to NLLB language codes
 */
const mapLanguageCode = (code) => {
  const mapping = {
    'en': 'eng_Latn',
    'es': 'spa_Latn',
    'fr': 'fra_Latn',
    'de': 'deu_Latn',
    'it': 'ita_Latn',
    'pt': 'por_Latn',
    'ru': 'rus_Cyrl',
    'ar': 'arb_Arab',
    'zh': 'zho_Hans',
    'ja': 'jpn_Jpan',
    'ko': 'kor_Hang',
    'hi': 'hin_Deva',
    'tr': 'tur_Latn',
    'nl': 'nld_Latn',
    'pl': 'pol_Latn',
    'ur': 'urd_Arab',  // Urdu
    'ps': 'pbt_Arab',  // Pashto
    'fa': 'prs_Arab'   // Dari (Persian/Farsi)
  };
  
  return mapping[code] || code;
};

/**
 * Batch translate multiple texts (for efficiency)
 */
export const batchTranslate = async (texts, sourceLanguage, targetLanguage) => {
  try {
    const translations = await Promise.all(
      texts.map(text => translateText(text, sourceLanguage, targetLanguage))
    );
    return translations;
  } catch (error) {
    logger.error('Batch translation error:', error);
    throw error;
  }
};
