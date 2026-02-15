import express from 'express';
import authRoutes from './auth.routes.js';
import sessionRoutes from './session.routes.js';
import translationRoutes from './translation.routes.js';
import userRoutes from './user.routes.js';

const router = express.Router();

// Health check
router.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Routes
router.use('/auth', authRoutes);
router.use('/sessions', sessionRoutes);
router.use('/translations', translationRoutes);
router.use('/users', userRoutes);

export default router;
