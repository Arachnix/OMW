/**
 * User Profiles & Student Authentication Endpoints
 */
import { Router } from 'express';
import { store } from '../data/store.js';
import { maskRegNumber } from '../utils/crypto.js';
import { parseVitEmail, verifyGoogleIdToken, generateVitRegNumber } from '../utils/vitAuth.js';

const router = Router();

/**
 * POST /api/auth/vit-verify
 * Validates a VIT student email and returns parsed identity & academic standing
 */
router.post('/vit-verify', (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({
      success: false,
      error: 'Student email is required'
    });
  }

  const parsed = parseVitEmail(email);
  if (!parsed.isValidVit) {
    return res.status(403).json({
      success: false,
      isValidVit: false,
      error: parsed.error
    });
  }

  res.json({
    success: true,
    ...parsed
  });
});

/**
 * POST /api/auth/google
 * Google OAuth sign-in / registration for VIT students with 20-token promotional airdrop
 */
router.post('/google', async (req, res) => {
  const { idToken, email, name, hostelBlock = 'Hostel Block Unassigned' } = req.body;

  try {
    // 1. Verify Google OAuth token (or mock dev token)
    const tokenData = await verifyGoogleIdToken(idToken, { email, name });
    const userEmail = tokenData.email || email;

    // 2. Strict VIT domain verification & name/year parsing
    const parsed = parseVitEmail(userEmail);
    if (!parsed.isValidVit) {
      return res.status(403).json({
        success: false,
        error: parsed.error || 'Access restricted: Only verified VIT students (@vitstudent.ac.in) are permitted'
      });
    }

    // 3. Check if user already exists
    let user = store.findUserByEmail(parsed.email);
    let isNewUser = false;

    if (!user) {
      isNewUser = true;
      const newId = `usr-${Date.now().toString().slice(-4)}`;
      const regNumber = generateVitRegNumber(parsed.admissionYear);

      user = store.createUser({
        id: newId,
        name: parsed.fullName || tokenData.name || 'VIT Student',
        email: parsed.email,
        admissionYear: parsed.admissionYear,
        academicStanding: parsed.academicStanding,
        regNumber,
        regHash: maskRegNumber(regNumber),
        hostelBlock,
        trustScore: 5.0,
        completedTasks: 0,
        isRestricted: false,
        role: 'student'
      }, 20); // 20 promotional non-cashable airdrop tokens!
    }

    const wallet = store.getWallet(user.id);

    res.json({
      success: true,
      message: isNewUser
        ? 'Welcome to OMW! 20 promotional tokens have been airdropped to your wallet.'
        : 'Authenticated successfully with VIT Google Account',
      isNewUser,
      user,
      token: `omw_jwt_google_${user.id}`,
      airdrop: isNewUser ? {
        tokens: 20,
        type: 'WELCOME_AIRDROP',
        isCashable: false,
        description: '20 non-cashable promotional tokens to fund your initial campus microgigs'
      } : null,
      wallet
    });
  } catch (err) {
    res.status(400).json({
      success: false,
      error: err.message || 'Google authentication failed'
    });
  }
});

/**
 * POST /api/auth/login
 * Mock student authentication via VIT registration number (Legacy/Fallback)
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
    }, 20); // 20 welcome tokens
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
      email: user.email || null,
      admissionYear: user.admissionYear || null,
      academicStanding: user.academicStanding || null,
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
