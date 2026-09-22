/**
 * Wallet & Token Balance Endpoints
 */
import { Router } from 'express';
import { store } from '../data/store.js';
import { PaymentService } from '../services/payment/paymentService.js';
import { TOKEN_EXCHANGE_RATE } from '../utils/tokenomics.js';
import { requireAuth } from '../utils/auth.js';

const router = Router();

// Every wallet endpoint acts on the signed-in student's own wallet.
router.use(requireAuth);

/**
 * GET /api/wallet/balance
 * Returns available tokens, escrow locked, runner staked, and INR value
 */
router.get('/balance', (req, res) => {
  const user = req.user;
  const wallet = store.getWallet(user.id);

  const totalTokens = wallet.availableTokens + wallet.escrowLocked + wallet.runnerStaked;

  res.json({
    success: true,
    userId: user.id,
    userName: user.name,
    wallet: {
      availableTokens: wallet.availableTokens,
      escrowLocked: wallet.escrowLocked,
      runnerStaked: wallet.runnerStaked,
      totalNetTokens: totalTokens,
      exchangeRateInrPerToken: TOKEN_EXCHANGE_RATE,
      totalValueInr: totalTokens * TOKEN_EXCHANGE_RATE
    }
  });
});

/**
 * GET /api/wallet/transactions
 * Returns the signed-in student's ledger of token events
 */
router.get('/transactions', (req, res) => {
  const limit = req.query.limit ? parseInt(req.query.limit, 10) : 50;

  const transactions = store.getTransactions(req.user.id, limit);

  res.json({
    success: true,
    count: transactions.length,
    transactions
  });
});

/**
 * POST /api/wallet/withdraw
 * Cash-out tokens to UPI or campus voucher (Gazebo/Foody)
 */
router.post('/withdraw', (req, res) => {
  const { tokens, method = 'UPI', destination } = req.body;

  try {
    const result = PaymentService.processWithdrawal({
      userId: req.user.id,
      tokens: Number(tokens),
      method,
      destination
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
