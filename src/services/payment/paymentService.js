/**
 * Payment Service: Razorpay Test Network Gateway & Redemption
 */
import { store } from '../../data/store.js';
import { generateRazorpaySignature, verifyRazorpaySignature } from '../../utils/crypto.js';
import { TOKEN_EXCHANGE_RATE } from '../../utils/tokenomics.js';

const RAZORPAY_KEY_ID = process.env.RAZORPAY_KEY_ID || 'rzp_test_TdUr00Z69QcuAt';
const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET || 'rzp_test_secret_omw2026';

export class PaymentService {
  /**
   * Generates a Razorpay INR test order to buy token packs.
   * Pegged at ₹1 per token (TOKEN_EXCHANGE_RATE = 1).
   */
  static createRazorpayOrder(tokenAmount, userId) {
    if (!tokenAmount || tokenAmount <= 0) {
      throw new Error('Token amount must be greater than 0');
    }

    const amountInr = tokenAmount * TOKEN_EXCHANGE_RATE;
    const amountSubunits = amountInr * 100; // Razorpay expects paise (1 INR = 100 paise)
    const orderId = `order_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;

    return {
      orderId,
      amountInr,
      amountSubunits,
      currency: 'INR',
      keyId: RAZORPAY_KEY_ID,
      exchangeRate: TOKEN_EXCHANGE_RATE,
      tokenAmount,
      customer: {
        userId
      }
    };
  }

  /**
   * Verifies Razorpay payment signature and credits tokens to user wallet
   */
  static verifyAndCreditPayment({
    orderId,
    paymentId,
    signature,
    tokenAmount,
    userId
  }) {
    if (!orderId || !paymentId) {
      throw new Error('Missing orderId or paymentId');
    }

    // If signature provided, verify cryptographically; or accept in sandbox test simulation
    let isValid = false;
    if (signature) {
      isValid = verifyRazorpaySignature(orderId, paymentId, signature, RAZORPAY_KEY_SECRET);
      if (!isValid) {
        // Allow sandbox simulation signature if testing
        const expected = generateRazorpaySignature(orderId, paymentId, RAZORPAY_KEY_SECRET);
        isValid = signature === expected || signature === 'test_mock_signature';
      }
    } else {
      // In sandbox mode without signature, simulate verification
      isValid = true;
    }

    if (!isValid) {
      throw new Error('Invalid Razorpay payment signature');
    }

    const tokensToCredit = Number(tokenAmount);
    const wallet = store.getWallet(userId);
    wallet.availableTokens += tokensToCredit;

    const tx = store.addTransaction({
      userId,
      type: 'TOKEN_PURCHASE',
      tokens: tokensToCredit,
      amountInr: tokensToCredit * TOKEN_EXCHANGE_RATE,
      reference: `Razorpay Order ${orderId} (Payment ${paymentId})`,
      status: 'COMPLETED'
    });

    return {
      success: true,
      creditedTokens: tokensToCredit,
      newAvailableBalance: wallet.availableTokens,
      transactionId: tx.id,
      inrCharged: tokensToCredit * TOKEN_EXCHANGE_RATE
    };
  }

  /**
   * Withdraws surplus runner tokens or redeems closed-loop campus vouchers
   */
  static processWithdrawal({
    userId,
    tokens,
    method = 'UPI',
    destination = ''
  }) {
    const wallet = store.getWallet(userId);
    if (!tokens || tokens <= 0) {
      throw new Error('Withdrawal token amount must be greater than 0');
    }
    if (wallet.availableTokens < tokens) {
      throw new Error(`Insufficient tokens for withdrawal. Available: ${wallet.availableTokens}, Requested: ${tokens}`);
    }

    wallet.availableTokens -= tokens;
    const amountInr = tokens * TOKEN_EXCHANGE_RATE;

    const tx = store.addTransaction({
      userId,
      type: method === 'VOUCHER' ? 'VOUCHER_REDEMPTION' : 'FIAT_WITHDRAWAL',
      tokens: -tokens,
      amountInr,
      reference: method === 'VOUCHER' 
        ? `Campus Vendor Voucher: ${destination || 'Gazebo Food Court'}`
        : `UPI Payout to ${destination || 'runner@upi'}`,
      status: 'COMPLETED'
    });

    return {
      success: true,
      withdrawnTokens: tokens,
      inrValue: amountInr,
      method,
      destination,
      remainingTokens: wallet.availableTokens,
      transactionId: tx.id
    };
  }
}
