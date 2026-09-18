/**
 * User Profiles & Student Authentication Endpoints
 */
import { Router } from 'express';
import { store } from '../data/store.js';
import { maskRegNumber } from '../utils/crypto.js';

const router = Router();

/**
 * POST /api/auth/login
 * Mock student authentication via VIT registration number
 */
router.post('/login', (req, res) => {
  const { regNumber, name, hostelBlock = 'Hostel Block' } = req.body;

  if (!regNumber || !name) {
    return res.status(400).json({
      success: false,
      error: 'Registration number and student name are required'
    });
  }

  let user = store.findUserByReg(regNumber);

  if (!user) {
    const newId = `usr-${Date.now().toString().slice(-4)}`;
    user = store.createUser({
      id: newId,
      name,
      regNumber,
      regHash: maskRegNumber(regNumber),
      hostelBlock,
      trustScore: 5.0,
      completedTasks: 0,
      isRestricted: false,
      role: 'student'
    });
  }

  const wallet = store.getWallet(user.id);

  res.json({
    success: true,
    message: 'Authenticated successfully',
    user,
    token: `omw_jwt_mock_${user.id}`,
    wallet
  });
});

/**
 * GET /api/users/me
 * Returns current authenticated user (defaults to demo user)
 */
router.get('/me', (req, res) => {
  const userId = req.query.userId || 'usr-rohit';
  const user = store.getUser(userId);

  if (!user) {
    return res.status(404).json({ success: false, error: 'User not found' });
  }

  const wallet = store.getWallet(userId);

  res.json({
    success: true,
    user,
    wallet
  });
});

/**
 * GET /api/users/:id
 * Returns student public profile with trust rating & restriction notice
 */
router.get('/:id', (req, res) => {
  const user = store.getUser(req.params.id);

  if (!user) {
    return res.status(404).json({ success: false, error: 'Student not found' });
  }

  res.json({
    success: true,
    profile: {
      id: user.id,
      name: user.name,
      regHash: user.regHash,
      hostelBlock: user.hostelBlock,
      trustScore: user.trustScore,
      completedTasks: user.completedTasks,
      isRestricted: user.isRestricted,
      restrictionNotice: user.restrictionNotice || null,
      role: user.role
    }
  });
});

export default router;
