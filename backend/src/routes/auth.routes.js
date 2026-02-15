import express from 'express';
import { register, login, refreshToken, logout, socialLogin } from '../controllers/auth.controller.js';
import { validateRequest } from '../middleware/validation.js';
import { registerSchema, loginSchema } from '../validators/auth.validator.js';

const router = express.Router();

router.post('/register', validateRequest(registerSchema), register);
router.post('/login', validateRequest(loginSchema), login);
router.post('/refresh', refreshToken);
router.post('/logout', logout);
router.post('/social/:provider', socialLogin); // Google, Apple, Facebook

export default router;
