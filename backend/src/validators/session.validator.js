import { z } from 'zod';
import { config } from '../config/index.js';

export const createSessionSchema = z.object({
  language: z.enum(config.supportedLanguages, {
    errorMap: () => ({ message: 'Unsupported language' })
  })
});

export const joinSessionSchema = z.object({
  sessionCode: z.string().length(6, 'Session code must be 6 characters'),
  language: z.enum(config.supportedLanguages, {
    errorMap: () => ({ message: 'Unsupported language' })
  })
});
