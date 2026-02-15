import jwt from 'jsonwebtoken';
import { config } from '../config/index.js';

export const generateToken = (userId) => {
  return jwt.sign(
    { userId },
    config.jwt.secret,
    { expiresIn: config.jwt.expiry }
  );
};

export const generateRefreshToken = (userId) => {
  return jwt.sign(
    { userId, type: 'refresh' },
    config.jwt.secret,
    { expiresIn: config.jwt.refreshExpiry }
  );
};

export const verifyToken = (token) => {
  return jwt.verify(token, config.jwt.secret);
};
