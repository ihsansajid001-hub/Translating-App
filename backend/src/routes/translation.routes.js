import express from 'express';
import { getSupportedLanguages, getTranslationStats } from '../controllers/translation.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

router.get('/languages', getSupportedLanguages);
router.get('/stats', authenticate, getTranslationStats);

export default router;
