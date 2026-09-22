/**
 * User Profiles & Student Authentication Endpoints
 */
import { Router } from 'express';
import { store } from '../data/store.js';
import { maskRegNumber } from '../utils/crypto.js';
import { requireAuth, signToken } from '../utils/auth.js';

const router = Router();

/**
 * POST /api/auth/login
 * Student sign-in via VIT registration number. Returns a signed session token
 * the client sends as `Authorization: Bearer <token>` on every other request.
 * There is no password or email check yet, so knowing a registration number
 * is enough to sign in as that student.
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
    token: signToken(user),
    wallet
  });
});

/**
 * GET /api/users/me
 * Returns the signed-in student and their wallet
 */
router.get('/me', requireAuth, (req, res) => {
  const user = req.user;
  const wallet = store.getWallet(user.id);

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
router.get('/:id', requireAuth, (req, res) => {
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
