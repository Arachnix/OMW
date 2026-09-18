/**
 * Comprehensive Automated Test for Official Razorpay Test Network Integration
 * Tests: Live Order Creation, HMAC Signature Verification, Supabase Minting & Fiat Cashout
 */
import { PaymentService } from '../src/services/payment/paymentService.js';
import { store } from '../src/data/store.js';
import { WalletRepository } from '../src/db/repositories/walletRepository.js';
import crypto from 'crypto';
import dotenv from 'dotenv';

dotenv.config();

let passed = 0;
let failed = 0;

function assert(condition, message) {
  if (condition) {
    console.log(`  ✓ ${message}`);
    passed++;
  } else {
    console.error(`  ✗ FAIL: ${message}`);
    failed++;
  }
}

async function runPaymentTests() {
  console.log('======================================================');
  console.log('💳 Starting Razorpay Test Network & Fiat Cashout Tests');
  console.log('======================================================\n');

  // 1. Live Order Creation
  console.log('👉 1. Testing Live Razorpay Order Creation:');
  const tokenAmount = 75;
  const order = await PaymentService.createRazorpayOrder(tokenAmount, 'usr-rohit');

  assert(order && order.orderId, `Order created with ID: ${order.orderId}`);
  assert(order.amountSubunits === 7500, `Amount in subunits: ${order.amountSubunits} paise (₹75 INR)`);
  assert(order.currency === 'INR', 'Currency is INR');
  assert(order.tokenAmount === 75, 'Token purchase quantity matches 75 tokens');

  // 2. Cryptographic Signature Generation & Verification
  console.log('\n👉 2. Testing Payment Signature Verification & Supabase Wallet Crediting:');
  const initialWallet = store.getWallet('usr-rohit');
  const initialBalance = initialWallet.availableTokens;

  const mockPaymentId = `pay_test_${Date.now()}`;
  const validSignature = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || '')
    .update(`${order.orderId}|${mockPaymentId}`)
    .digest('hex');

  const paymentResult = await PaymentService.verifyAndCreditPayment({
    orderId: order.orderId,
    paymentId: mockPaymentId,
    signature: validSignature,
    tokenAmount: 75,
    userId: 'usr-rohit'
  });

  assert(paymentResult.success === true, 'Payment verification succeeded');
  assert(paymentResult.creditedTokens === 75, '75 tokens credited to wallet');
  assert(paymentResult.newAvailableBalance === initialBalance + 75, `New balance updated to ${paymentResult.newAvailableBalance}`);
  assert(paymentResult.transactionId, `Transaction logged: ${paymentResult.transactionId}`);

  // 3. Test Invalid Signature Rejection
  console.log('\n👉 3. Testing Tampered Signature Rejection:');
  try {
    await PaymentService.verifyAndCreditPayment({
      orderId: order.orderId,
      paymentId: 'pay_fraud_attempt',
      signature: 'invalid_tampered_signature',
      tokenAmount: 500,
      userId: 'usr-rohit'
    });
    assert(false, 'Should have thrown error on tampered signature');
  } catch (err) {
    assert(err.message === 'Invalid Razorpay payment signature', 'Successfully blocked payment with invalid signature');
  }

  // 4. Fiat Cashout (Runner Payout via UPI)
  console.log('\n👉 4. Testing Runner Fiat Cashout (UPI Payout):');
  const runnerWallet = store.getWallet('usr-rohan');
  const runnerInitialBalance = runnerWallet.availableTokens;

  const cashoutResult = await PaymentService.processFiatCashout({
    userId: 'usr-rohan',
    tokens: 30,
    method: 'UPI',
    destination: 'rohan.mehta@oksbi'
  });

  assert(cashoutResult.success === true, 'Fiat cashout processed successfully');
  assert(cashoutResult.withdrawnTokens === 30, '30 tokens deducted from runner');
  assert(cashoutResult.inrValue === 30, '₹30 INR paid out');
  assert(cashoutResult.destination === 'rohan.mehta@oksbi', 'Payout directed to rohan.mehta@oksbi');
  assert(cashoutResult.remainingTokens === runnerInitialBalance - 30, `Runner balance updated to ${cashoutResult.remainingTokens}`);
  assert(cashoutResult.payoutId && cashoutResult.payoutId.startsWith('pout_test_'), `Razorpay payout reference: ${cashoutResult.payoutId}`);

  // 5. Anti-Fraud Enforcement on Cashout (Restricted Account)
  console.log('\n👉 5. Testing TrustShield Anti-Fraud Cashout Guard:');
  try {
    await PaymentService.processFiatCashout({
      userId: 'usr-rahul', // Restricted account
      tokens: 10,
      method: 'UPI',
      destination: 'rahul.fraud@upi'
    });
    assert(false, 'Restricted account should NOT be allowed to cash out');
  } catch (err) {
    assert(err.message.includes('Account restricted'), 'Successfully blocked cashout from TrustShield restricted account');
  }

  // 6. Insufficient Balance Guard
  console.log('\n👉 6. Testing Insufficient Balance Cashout Guard:');
  try {
    await PaymentService.processFiatCashout({
      userId: 'usr-rohan',
      tokens: 999999, // Way more than available
      method: 'UPI',
      destination: 'rohan.mehta@oksbi'
    });
    assert(false, 'Excessive cashout should be blocked');
  } catch (err) {
    assert(err.message.includes('Insufficient tokens'), 'Successfully blocked withdrawal with insufficient tokens');
  }

  console.log('\n======================================================');
  console.log(`📊 Razorpay Test Results: ${passed} Passed, ${failed} Failed`);
  console.log('======================================================\n');

  if (failed > 0) process.exit(1);
}

runPaymentTests().catch(err => {
  console.error('Fatal Payment Test Error:', err);
  process.exit(1);
});
