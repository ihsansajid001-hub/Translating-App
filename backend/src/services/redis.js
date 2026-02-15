import Redis from 'ioredis';
import { config } from '../config/index.js';
import { logger } from '../utils/logger.js';

let redis;

// Check if Redis is available
const isRedisAvailable = config.redis.url && !config.redis.url.includes('localhost');

if (config.redis.token) {
  // Upstash Redis (production)
  redis = new Redis(config.redis.url, {
    token: config.redis.token,
    tls: {
      rejectUnauthorized: false
    }
  });
} else if (isRedisAvailable) {
  // Local Redis (development)
  redis = new Redis(config.redis.url);
} else {
  // Mock Redis for demo mode
  logger.warn('⚠️  Redis not available - using IN-MEMORY CACHE (demo mode)');
  logger.warn('⚠️  For production, use Upstash Redis (free): https://upstash.com');
  
  // Simple in-memory cache
  const cache = new Map();
  const sets = new Map();
  
  redis = {
    get: async (key) => cache.get(key) || null,
    set: async (key, value) => { cache.set(key, value); return 'OK'; },
    setex: async (key, ttl, value) => { 
      cache.set(key, value);
      setTimeout(() => cache.delete(key), ttl * 1000);
      return 'OK';
    },
    del: async (...keys) => {
      keys.forEach(key => cache.delete(key));
      return keys.length;
    },
    hset: async (key, field, value) => {
      if (!cache.has(key)) cache.set(key, {});
      cache.get(key)[field] = value;
      return 1;
    },
    hget: async (key, field) => {
      const hash = cache.get(key);
      return hash ? hash[field] : null;
    },
    lpush: async (key, ...values) => {
      if (!cache.has(key)) cache.set(key, []);
      cache.get(key).unshift(...values);
      return cache.get(key).length;
    },
    lrange: async (key, start, stop) => {
      const list = cache.get(key) || [];
      return list.slice(start, stop + 1);
    },
    ltrim: async (key, start, stop) => {
      if (cache.has(key)) {
        const list = cache.get(key);
        cache.set(key, list.slice(start, stop + 1));
      }
      return 'OK';
    },
    llen: async (key) => {
      const list = cache.get(key);
      return list ? list.length : 0;
    },
    sadd: async (key, ...members) => {
      if (!sets.has(key)) sets.set(key, new Set());
      members.forEach(m => sets.get(key).add(m));
      return members.length;
    },
    srem: async (key, ...members) => {
      if (sets.has(key)) {
        members.forEach(m => sets.get(key).delete(m));
      }
      return members.length;
    },
    scard: async (key) => {
      return sets.has(key) ? sets.get(key).size : 0;
    },
    on: () => {},
  };
  
  logger.info('✅ In-memory cache initialized (demo mode)');
}

if (redis.on) {
  redis.on('connect', () => {
    logger.info('✅ Redis connected');
  });

  redis.on('error', (err) => {
    logger.error('Redis error:', err);
  });
}

export { redis };
