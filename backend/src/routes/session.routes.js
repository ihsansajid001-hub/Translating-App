import express from 'express';
import { 
  createSession, 
  joinSession, 
  getSession, 
  endSession,
  getSessionHistory,
  getActiveSessions
} from '../controllers/session.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { validateRequest } from '../middleware/validation.js';
import { createSessionSchema, joinSessionSchema } from '../validators/session.validator.js';

const router = express.Router();

// All session routes require authentication
router.use(authenticate);

router.post('/create', validateRequest(createSessionSchema), createSession);
router.post('/join', validateRequest(joinSessionSchema), joinSession);
router.get('/:sessionId', getSession);
router.delete('/:sessionId', endSession);
router.get('/:sessionId/history', getSessionHistory);
router.get('/user/active', getActiveSessions);

export default router;
