/**
 * Cryptographic, OTP Generation & Razorpay Signature Verification Helpers
 */
import crypto from 'crypto';

/**
 * Generates a 4-digit numeric OTP string (e.g. "4821")
 */
export function generateOtp() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

/**
 * Anonymizes a student registration number (e.g. "22BCE1042" -> "22BCE****")
 */
export function maskRegNumber(regNumber = '') {
  const clean = regNumber.trim().toUpperCase();
  if (clean.length <= 5) return clean;
  return clean.slice(0, 5) + '****';
}

/**
 * Generates HMAC-SHA256 signature for Razorpay test payments
 */
export function generateRazorpaySignature(orderId, paymentId, secret) {
  return crypto
    .createHmac('sha256', secret)
    .update(`${orderId}|${paymentId}`)
    .digest('hex');
}

/**
 * Verifies Razorpay payment signature
 */
export function verifyRazorpaySignature(orderId, paymentId, signature, secret) {
  const expected = generateRazorpaySignature(orderId, paymentId, secret);
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature));
}
