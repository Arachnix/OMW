/**
 * OMW — "ON MY WAY" Master Application & API Gateway Server
 * Hyper-Local Peer-to-Peer Campus Mobility & Logistics Engine
 */
import express from 'express';
import http from 'http';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Load environment configuration
dotenv.config();

import { isSupabaseLive } from './db/supabaseClient.js';

// Service & Route imports
import { socketService } from './services/socket/socketService.js';
import { liquidityDaemon } from './services/escrow/liquidityDaemon.js';
import mapRoutes from './routes/mapRoutes.js';
import taskRoutes from './routes/taskRoutes.js';
import walletRoutes from './routes/walletRoutes.js';
import paymentRoutes from './routes/paymentRoutes.js';
import trustshieldRoutes from './routes/trustshieldRoutes.js';
import userRoutes from './routes/userRoutes.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '..');

const app = express();
const server = http.createServer(app);

// Middleware
app.use(cors({ origin: '*' }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static frontend assets & ES module views
app.use(express.static(path.join(rootDir, 'public')));
app.use('/public', express.static(path.join(rootDir, 'public')));
app.use('/assets', express.static(path.join(rootDir, 'assets')));
app.use('/src', express.static(path.join(rootDir, 'src')));

// Master API Directory & Gateway Root
app.get(['/api', '/api/v1'], (req, res) => {
  const host = req.get('host') || 'omw-jout.onrender.com';
  const protocol = req.secure || req.headers['x-forwarded-proto'] === 'https' ? 'https' : 'http';
  const wsProtocol = protocol === 'https' ? 'wss' : 'ws';

  res.json({
    success: true,
    name: 'OMW (On My Way) Campus Logistics & Mobility Gateway',
    tagline: 'Hyper-Local Peer-to-Peer Campus Delivery & Escrow Protocol for VIT Vellore',
    version: '1.0.0',
    status: 'online',
    campus: 'Vellore Institute of Technology (VIT Vellore Main Campus)',
    database: isSupabaseLive() ? 'supabase_live' : 'hybrid_in_memory_fallback',
    peggedRate: '1 Token = ₹1 INR',
    documentation: 'https://github.com/codebreaker77/OMW/blob/main/docs/api/FLUTTER_INTEGRATION_GUIDE.md',
    websocket: `${wsProtocol}://${host}/ws`,
    liveSimulator: `${protocol}://${host}/public/tracking.html`,
    endpoints: {
      health: { method: 'GET', path: '/api/health', desc: 'System status & database tier' },
      mapLocations: { method: 'GET', path: '/api/map/locations', desc: '24 VIT Vellore landmark nodes' },
      mapCorridor: { method: 'GET', path: '/api/map/corridor', desc: '72 road-snapped GPS waypoints & navigation cues' },
      routeCalculate: { method: 'POST', path: '/api/map/route-calculate', desc: 'Pedestrian detour & walking time estimate' },
      tasks: { method: 'GET', path: '/api/tasks', desc: 'Active campus task feed sorted by corridor spatial priority' },
      calculateWager: { method: 'POST', path: '/api/tasks/calculate-wager', desc: 'Dynamic Smart Slider wager calculator' },
      createTask: { method: 'POST', path: '/api/tasks/create', desc: 'Post new task and lock requester escrow' },
      claimTask: { method: 'POST', path: '/api/tasks/:id/claim', desc: 'Runner locks 25% commitment deposit' },
      verifyPickup: { method: 'POST', path: '/api/tasks/:id/verify-pickup', desc: 'Verify source pickup OTP' },
      verifyDelivery: { method: 'POST', path: '/api/tasks/:id/verify-delivery', desc: 'Verify destination delivery OTP & atomic payout' },
      cancelTask: { method: 'POST', path: '/api/tasks/:id/cancel', desc: 'Requester cancels and receives 100% escrow refund' },
      walletBalance: { method: 'GET', path: '/api/wallet/balance?userId=usr-rohit', desc: 'Tokens available, locked & staked' },
      createPaymentOrder: { method: 'POST', path: '/api/payments/create-order', desc: 'Official Razorpay order generation' },
      verifyPayment: { method: 'POST', path: '/api/payments/verify-payment', desc: 'HMAC-SHA256 signature verification' },
      fiatCashout: { method: 'POST', path: '/api/payments/cashout', desc: 'Direct runner fiat cashout to UPI/bank' },
      trustshieldShowcase: { method: 'GET', path: '/api/trustshield/showcase', desc: 'Fraud of the Day & Month editorial deterrence' },
      userProfile: { method: 'GET', path: '/api/users/:id', desc: 'Student trust score & masked reg number' }
    }
  });
});

// Health check & System Metadata
app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    system: 'OMW Campus Logistics Gateway',
    version: '1.0.0',
    targetCampus: 'Vellore Institute of Technology (VIT Vellore Main Campus)',
    database: isSupabaseLive() ? 'supabase_live' : 'hybrid_in_memory_fallback',
    timestamp: new Date().toISOString(),
    port: process.env.PORT || 3033,
    peggedRate: '1 Token = ₹1 INR'
  });
});

// Mount Domain API Routes
app.use('/api/map', mapRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/trustshield', trustshieldRoutes);
app.use('/api/admin/fraud', trustshieldRoutes);
app.use('/api/users', userRoutes);
app.use('/api/auth', userRoutes); // Aliased for /api/auth/login

// 404 Fallback for unmatched routes
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: `Endpoint ${req.method} ${req.originalUrl} not found on OMW Server`
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('[OMW Server Error]:', err);
  res.status(500).json({
    success: false,
    error: err.message || 'Internal Server Error'
  });
});

// Initialize WebSocket Service on /ws
socketService.init(server);

// Start Server
const PORT = process.env.PORT || 3033;
server.listen(PORT, () => {
  console.log('====================================================');
  console.log(`🚀 OMW Campus Mobility Engine running on port ${PORT}`);
  console.log(`📡 REST API Base:  http://localhost:${PORT}/api`);
  console.log(`⚡ WebSocket Hub: ws://localhost:${PORT}/ws`);
  console.log(`🏛️ Target Campus:  VIT Vellore Main Campus`);
  console.log(`💰 Pegged Value:   1 Token = ₹1 INR`);
  console.log(`🗄️ Database Tier:  ${isSupabaseLive() ? 'Supabase PostgreSQL (Live)' : 'Hybrid In-Memory Fallback'}`);
  console.log('====================================================');

  // Start Background Liquidity Daemon
  liquidityDaemon.start();
});

export { app, server };
