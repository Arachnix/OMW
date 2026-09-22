/**
 * Session Tokens & Route Guards
 *
 * Tokens are `<payload>.<signature>`: a base64url JSON payload signed with
 * HMAC-SHA256. The server never trusts a user id sent in a request body or
 * query string; it reads the caller from the verified token instead.
 */
import crypto from 'crypto';
import { store } from '../data/store.js';

const TOKEN_TTL_MS = 7 * 24 * 60 * 60 * 1000;

// Without a configured secret, a random one is used and sessions end when the
// server restarts. Set OMW_AUTH_SECRET in .env to keep sessions across restarts.
const SECRET = process.env.OMW_AUTH_SECRET || crypto.randomBytes(32).toString('hex');

function sign(payload) {
  return crypto.createHmac('sha256', SECRET).update(payload).digest('base64url');
}

/**
 * Issues a session token for a user.
 */
export function signToken(user) {
  const now = Date.now();
  const payload = Buffer.from(
    JSON.stringify({ sub: user.id, role: user.role, iat: now, exp: now + TOKEN_TTL_MS })
  ).toString('base64url');
  return `${payload}.${sign(payload)}`;
}

/**
 * Returns the user a token belongs to, or null when the token is missing,
 * tampered with, expired, or names an unknown user.
 */
export function verifyToken(token) {
  if (typeof token !== 'string') return null;
  const [payload, signature] = token.split('.');
  if (!payload || !signature) return null;

  const expected = Buffer.from(sign(payload));
  const given = Buffer.from(signature);
  if (expected.length !== given.length || !crypto.timingSafeEqual(expected, given)) {
    return null;
  }

  let claims;
  try {
    claims = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
  } catch {
    return null;
  }
  if (!claims.sub || typeof claims.exp !== 'number' || claims.exp < Date.now()) {
    return null;
  }
  return store.getUser(claims.sub) || null;
}

/**
 * Express middleware: requires `Authorization: Bearer <token>` and sets
 * `req.user` to the signed-in student.
 */
export function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7).trim() : null;
  const user = verifyToken(token);

  if (!user) {
    return res.status(401).json({
      success: false,
      error: 'Sign in required. Your session is missing or has expired.'
    });
  }

  req.user = user;
  next();
}

/**
 * Express middleware: allows only users with one of the given roles.
 * Use after requireAuth.
 */
export function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: 'You do not have permission to do this.'
      });
    }
    next();
  };
}
