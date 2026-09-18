/**
 * Wallet & Token Balance Endpoints
 */
import { Router } from 'express';
import { store } from '../data/store.js';
import { PaymentService } from '../services/payment/paymentService.js';
import { TOKEN_EXCHANGE_RATE } from '../utils/tokenomics.js';

const router = Router();

/**
 * GET /api/wallet/balance
 * Returns available tokens, escrow locked, runner staked, and INR value
 */
router.get('/balance', (req, res) => {
  const userId = req.query.userId || 'usr-rohit';
  const wallet = store.getWallet(userId);
  const user = store.getUser(userId);

  const totalTokens = wallet.availableTokens + wallet.escrowLocked + wallet.runnerStaked;

  res.json({
    success: true,
    userId,
    userName: user ? user.name : 'Student',
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
 * Returns ledger of all token events
 */
router.get('/transactions', (req, res) => {
  const userId = req.query.userId;
  const limit = req.query.limit ? parseInt(req.query.limit, 10) : 50;

  const transactions = store.getTransactions(userId, limit);

  res.json({
    success: true,
    count: transactions.length,
    transactions
  });
});

/**
 * POST /api/wallet/withdraw
 * Fiat Cashout: Direct payout of earned tokens to UPI / Bank
 */
router.post('/withdraw', async (req, res) => {
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

export default router;
