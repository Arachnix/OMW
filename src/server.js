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

// Serve static frontend assets
app.use('/public', express.static(path.join(rootDir, 'public')));
app.use('/assets', express.static(path.join(rootDir, 'assets')));

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
});

export { app, server };
