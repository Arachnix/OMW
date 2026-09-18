/**
 * Razorpay Test Network Gateway Endpoints
 */
import { Router } from 'express';
import { PaymentService } from '../services/payment/paymentService.js';

const router = Router();

/**
 * POST /api/payments/create-order
 * Initiates Razorpay test order to buy token pack (pegged at ₹1/token)
 */
router.post('/create-order', (req, res) => {
  const { tokenAmount, userId = 'usr-rohit' } = req.body;

  try {
    const order = PaymentService.createRazorpayOrder(Number(tokenAmount), userId);
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
 * Validates Razorpay HMAC-SHA256 signature and credits tokens
 */
router.post('/verify-payment', (req, res) => {
  const {
    razorpay_order_id,
    razorpay_payment_id,
    razorpay_signature,
    tokenAmount,
    userId = 'usr-rohit'
  } = req.body;

  try {
    const result = PaymentService.verifyAndCreditPayment({
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

export default router;
