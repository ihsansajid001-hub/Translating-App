export const config = {
  // Server
  port: process.env.PORT || 3000,
  wsPort: process.env.WS_PORT || 3001,
  nodeEnv: process.env.NODE_ENV || 'development',
  
  // Supabase
  supabase: {
    url: process.env.SUPABASE_URL,
    anonKey: process.env.SUPABASE_ANON_KEY,
    serviceKey: process.env.SUPABASE_SERVICE_KEY
  },
  
  // Redis
  redis: {
    url: process.env.UPSTASH_REDIS_URL || 'redis://localhost:6379',
    token: process.env.UPSTASH_REDIS_TOKEN
  },
  
  // JWT
  jwt: {
    secret: process.env.JWT_SECRET || 'change-this-secret',
    expiry: process.env.JWT_EXPIRY || '15m',
    refreshExpiry: process.env.REFRESH_TOKEN_EXPIRY || '7d'
  },
  
  // AI Services
  ai: {
    mode: process.env.AI_MODE || 'local', // 'local', 'huggingface', 'hybrid'
    huggingfaceApiKey: process.env.HUGGINGFACE_API_KEY,
    sttServiceUrl: process.env.STT_SERVICE_URL || 'http://localhost:5000',
    translationServiceUrl: process.env.TRANSLATION_SERVICE_URL || 'http://localhost:5001',
    ttsServiceUrl: process.env.TTS_SERVICE_URL || 'http://localhost:5002',
    whisperModel: process.env.WHISPER_MODEL || 'base',
    nllbModel: process.env.NLLB_MODEL || 'nllb-200-distilled-600M',
    ttsEngine: process.env.TTS_ENGINE || 'piper'
  },
  
  // Performance
  maxAudioChunkSize: parseInt(process.env.MAX_AUDIO_CHUNK_SIZE) || 100,
  translationCacheTTL: parseInt(process.env.TRANSLATION_CACHE_TTL) || 86400,
  maxConcurrentSessions: parseInt(process.env.MAX_CONCURRENT_SESSIONS) || 100,
  
  // Rate Limiting
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW) || 60000,
    maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100
  },
  
  // CORS
  corsOrigin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
  
  // Feature Flags
  features: {
    offlineMode: process.env.ENABLE_OFFLINE_MODE === 'true',
    conversationHistory: process.env.ENABLE_CONVERSATION_HISTORY === 'true',
    qualityIndicators: process.env.ENABLE_QUALITY_INDICATORS === 'true',
    voiceActivityDetection: process.env.ENABLE_VOICE_ACTIVITY_DETECTION === 'true'
  },
  
  // Supported Languages
  supportedLanguages: process.env.SUPPORTED_LANGUAGES?.split(',') || [
    'en', 'es', 'fr', 'de', 'it', 'pt', 'ru', 'ar', 'zh', 'ja', 'ko', 'hi', 'tr', 'nl', 'pl'
  ]
};
