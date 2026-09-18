/**
 * Razorpay Test Network Gateway & Fiat Cashout Endpoints
 */
import { Router } from 'express';
import { PaymentService } from '../services/payment/paymentService.js';

const router = Router();

/**
 * POST /api/payments/create-order
 * Initiates an official Razorpay test order to buy token packs
 */
router.post('/create-order', async (req, res) => {
  const { tokenAmount, userId = 'usr-rohit' } = req.body;

  try {
    const order = await PaymentService.createRazorpayOrder(Number(tokenAmount), userId);
    res.json({
      success: true,
      order
    });
  } catch (err) {
    res.status(400).json({
      success: false,
      error: err.message
    });
  }
});

/**
 * POST /api/payments/verify-payment
 * Validates Razorpay HMAC-SHA256 signature and credits tokens to Supabase wallet
 */
router.post('/verify-payment', async (req, res) => {
  const {
    razorpay_order_id,
    razorpay_payment_id,
    razorpay_signature,
    tokenAmount,
    userId = 'usr-rohit'
  } = req.body;

  try {
    const result = await PaymentService.verifyAndCreditPayment({
      orderId: razorpay_order_id,
      paymentId: razorpay_payment_id,
      signature: razorpay_signature,
      tokenAmount,
      userId
    });

    res.json(result);
  } catch (err) {
    res.status(400).json({
      success: false,
      error: err.message
    });
  }
});

/**
 * POST /api/payments/cashout
 * Direct Fiat Cashout (UPI / Bank Transfer) for runner earnings
 */
router.post('/cashout', async (req, res) => {
  const {
    userId = 'usr-rohan',
    tokens,
    method = 'UPI',
    destination,
    accountNumber,
    ifsc
  } = req.body;

  try {
    const result = await PaymentService.processFiatCashout({
      userId,
      tokens: Number(tokens),
      method,
      destination,
      accountNumber,
      ifsc
    });

    res.json(result);
  } catch (err) {
    res.status(400).json({
      success: false,
      error: err.message
    });
  }
});

/**
 * POST /api/payments/webhook
 * Handles incoming Razorpay webhook event notifications
 */
router.post('/webhook', (req, res) => {
  const signature = req.headers['x-razorpay-signature'];
  const event = req.body;

  try {
    // In live production, verify signature with raw payload
    console.log(`📡 [Razorpay Webhook]: Received event '${event.event || 'unknown'}'`);
    res.json({ status: 'ok', received: true });
  } catch (err) {
    res.status(400).json({ success: false, error: err.message });
  }
});

export default router;
