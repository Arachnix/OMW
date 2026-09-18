/**
 * Reactive In-Memory State Store for OMW Backend
 */
import { VIT_LOCATIONS, INITIAL_FRAUD_CASES } from './campus-data.js';
import { isSupabaseLive, supabase } from '../db/supabaseClient.js';
import { UserRepository } from '../db/repositories/userRepository.js';
import { WalletRepository } from '../db/repositories/walletRepository.js';
import { TaskRepository } from '../db/repositories/taskRepository.js';
import { FraudRepository } from '../db/repositories/fraudRepository.js';

class DataStore {
  constructor() {
    this.locations = [...VIT_LOCATIONS];
    this.fraudCases = JSON.parse(JSON.stringify(INITIAL_FRAUD_CASES));

    // Seeded Users
    this.users = new Map([
      ['usr-rohit', {
        id: 'usr-rohit',
        name: 'Rohit Verma',
        email: 'rohit.verma2024@vitstudent.ac.in',
        admissionYear: 2024,
        academicStanding: '3rd Year (Junior)',
        regNumber: '22BCE1142',
        regHash: '22BCE****',
        hostelBlock: 'Q Block',
        trustScore: 4.9,
        completedTasks: 34,
        isRestricted: false,
        role: 'student'
      }],
      ['usr-rohan', {
        id: 'usr-rohan',
        name: 'Rohan Mehta',
        email: 'rohan.mehta2025@vitstudent.ac.in',
        admissionYear: 2025,
        academicStanding: '2nd Year (Sophomore)',
        regNumber: '22BEE0819',
        regHash: '22BEE****',
        hostelBlock: 'P Block',
        trustScore: 4.8,
        completedTasks: 52,
        isRestricted: false,
        role: 'runner'
      }],
      ['usr-rahul', {
        id: 'usr-rahul',
        name: 'Rahul S.',
        email: 'rahul.s2024@vitstudent.ac.in',
        admissionYear: 2024,
        academicStanding: '3rd Year (Junior)',
        regNumber: '22BCE0089',
        regHash: '22BCE****',
        hostelBlock: 'Q Block',
        trustScore: 1.2,
        completedTasks: 8,
        isRestricted: true,
        restrictionNotice: '⚠ OMW ACCOUNT RESTRICTED — Collusive dual-OTP violation detected',
        role: 'student'
      }],
      ['usr-proctor', {
        id: 'usr-proctor',
        name: 'Student Proctor Ops',
        email: 'proctor.ops@vitstudent.ac.in',
        admissionYear: 2022,
        academicStanding: 'Campus Proctor / Administrator',
        regNumber: 'PROCTOR-01',
        regHash: 'ADMIN****',
        hostelBlock: 'Main Building',
        trustScore: 5.0,
        completedTasks: 0,
        isRestricted: false,
        role: 'admin'
      }]
    ]);

    // Seeded Wallets (Token Balances: bonusTokens non-cashable + cashableTokens)
    this.wallets = new Map([
      ['usr-rohit', {
        userId: 'usr-rohit',
        availableTokens: 85,
        bonusTokens: 0,
        cashableTokens: 85,
        escrowLocked: 0,
        runnerStaked: 0
      }],
      ['usr-rohan', {
        userId: 'usr-rohan',
        availableTokens: 140,
        bonusTokens: 0,
        cashableTokens: 140,
        escrowLocked: 0,
        runnerStaked: 0
      }],
      ['usr-rahul', {
        userId: 'usr-rahul',
        availableTokens: 0,
        bonusTokens: 0,
        cashableTokens: 0,
        escrowLocked: 0,
        runnerStaked: 0
      }],
      ['usr-proctor', {
        userId: 'usr-proctor',
        availableTokens: 1000,
        bonusTokens: 0,
        cashableTokens: 1000,
        escrowLocked: 0,
        runnerStaked: 0
      }]
    ]);

    // Seeded Transactions Ledger
    this.transactions = [
      {
        id: 'tx-init-1',
        userId: 'usr-rohit',
        type: 'TOKEN_PURCHASE',
        tokens: 100,
        amountInr: 100,
        timestamp: new Date(Date.now() - 86400000).toISOString(),
        reference: 'Razorpay Pack rzp_test_001',
        status: 'COMPLETED'
      },
      {
        id: 'tx-init-2',
        userId: 'usr-rohan',
        type: 'RUNNER_PAYOUT',
        tokens: 40,
        amountInr: 40,
        timestamp: new Date(Date.now() - 43200000).toISOString(),
        reference: 'Delivered Task TSK-901',
        status: 'COMPLETED'
      }
    ];

    // Seeded Tasks
    this.tasks = new Map([
      ['TSK-101', {
        id: 'TSK-101',
        title: 'Pick up Darling Bakery Veg Puff & Cold Coffee',
        category: 'food',
        requesterId: 'usr-rohit',
        requesterName: 'Rohit Verma',
        requesterTrustScore: 4.9,
        pickupNodeId: 'loc-darling-bakery',
        pickupNodeName: 'Darling Bakery & Coffee Portico',
        pickupCoords: [12.9698, 79.1588],
        dropNodeId: 'loc-q-block',
        dropNodeName: 'Q Block Men\'s Residential Tower',
        dropCoords: [12.9726, 79.1624],
        wager: 18,
        notes: 'Keep cold coffee upright. Call upon reaching Q Block security turnstile.',
        urgency: 'normal',
        status: 'OPEN',
        runnerId: null,
        runnerName: null,
        pickupOtp: '4821',
        deliveryOtp: '7392',
        runnerStakeLocked: 0,
        createdAt: new Date(Date.now() - 600000).toISOString(),
        surgeActive: false
      }],
      ['TSK-102', {
        id: 'TSK-102',
        title: 'Collect 12-page Thermal Lab report printout',
        category: 'facility',
        requesterId: 'usr-rohit',
        requesterName: 'Rohit Verma',
        requesterTrustScore: 4.9,
        pickupNodeId: 'loc-tt-xerox',
        pickupNodeName: 'TT Ground Floor Central Xerox',
        pickupCoords: [12.9701, 79.1592],
        dropNodeId: 'loc-sjt',
        dropNodeName: 'Silver Jubilee Tower (SJT)',
        dropCoords: [12.9710, 79.1635],
        wager: 14,
        notes: 'Token #34 paid already at shop counter. Just show receipt screenshot.',
        urgency: 'urgent',
        status: 'OPEN',
        runnerId: null,
        runnerName: null,
        pickupOtp: '3159',
        deliveryOtp: '9841',
        runnerStakeLocked: 0,
        createdAt: new Date(Date.now() - 1200000).toISOString(),
        surgeActive: false
      }],
      ['TSK-103', {
        id: 'TSK-103',
        title: 'Swiggy parcel collection from Main Gate',
        category: 'food',
        requesterId: 'usr-rohit',
        requesterName: 'Rohit Verma',
        requesterTrustScore: 4.9,
        pickupNodeId: 'loc-main-gate',
        pickupNodeName: 'Main Gate Katpadi Entrance',
        pickupCoords: [12.9692, 79.1559],
        dropNodeId: 'loc-q-block',
        dropNodeName: 'Q Block Men\'s Residential Tower',
        dropCoords: [12.9726, 79.1624],
        wager: 24,
        notes: 'Order under name Rohit V, OTP for gate delivery boy is 66.',
        urgency: 'critical',
        status: 'CLAIMED',
        runnerId: 'usr-rohan',
        runnerName: 'Rohan Mehta',
        pickupOtp: '1102',
        deliveryOtp: '5543',
        runnerStakeLocked: 6,
        createdAt: new Date(Date.now() - 1800000).toISOString(),
        claimedAt: new Date(Date.now() - 900000).toISOString(),
        surgeActive: false
      }]
    ]);
  }

  // Location helpers
  getLocationById(id) {
    return this.locations.find(loc => loc.id === id);
  }

  // User helpers
  getUser(userId) {
    return this.users.get(userId);
  }

  findUserByReg(regNumber) {
    if (!regNumber) return null;
    const clean = regNumber.trim().toUpperCase();
    for (const user of this.users.values()) {
      if (user.regNumber && user.regNumber.toUpperCase() === clean) return user;
    }
    return null;
  }

  findUserByEmail(email) {
    if (!email) return null;
    const clean = email.trim().toLowerCase();
    for (const user of this.users.values()) {
      if (user.email && user.email.toLowerCase() === clean) return user;
    }
    return null;
  }

  createUser(userData, initialBonusTokens = 20) {
    this.users.set(userData.id, userData);
    if (!this.wallets.has(userData.id)) {
      this.wallets.set(userData.id, {
        userId: userData.id,
        availableTokens: initialBonusTokens,
        bonusTokens: initialBonusTokens, // 20 promotional non-cashable tokens
        cashableTokens: 0,
        escrowLocked: 0,
        runnerStaked: 0
      });

      if (initialBonusTokens > 0) {
        this.addTransaction({
          userId: userData.id,
          type: 'AIRDROP_BONUS',
          tokens: initialBonusTokens,
          amountInr: initialBonusTokens,
          reference: 'VIT Student Welcome Airdrop (20 Non-Cashable Gig Tokens)',
          status: 'COMPLETED'
        });
      }
    }
    if (isSupabaseLive()) {
      UserRepository.create(userData).catch(err => console.error('[Supabase User Sync Error]:', err.message));
    }
    return userData;
  }

  // Wallet & Transaction helpers
  getWallet(userId) {
    if (!this.wallets.has(userId)) {
      this.wallets.set(userId, {
        userId,
        availableTokens: 20,
        bonusTokens: 20,
        cashableTokens: 0,
        escrowLocked: 0,
        runnerStaked: 0
      });
    }
    const w = this.wallets.get(userId);
    if (w.bonusTokens === undefined) w.bonusTokens = 0;
    if (w.cashableTokens === undefined) w.cashableTokens = w.availableTokens;
    return w;
  }

  addTransaction(tx) {
    const record = {
      id: tx.id || `tx-${Date.now()}-${Math.random().toString(36).substr(2, 5)}`,
      timestamp: new Date().toISOString(),
      ...tx
    };
    this.transactions.unshift(record);
    if (isSupabaseLive()) {
      WalletRepository.addTransaction(record).catch(err => console.error('[Supabase Transaction Sync Error]:', err.message));
    }
    return record;
  }

  getTransactions(userId, limit = 50) {
    if (!userId) return this.transactions.slice(0, limit);
    return this.transactions
      .filter(tx => tx.userId === userId)
      .slice(0, limit);
  }

  // Task helpers
  getTask(taskId) {
    return this.tasks.get(taskId);
  }

  getAllTasks() {
    return Array.from(this.tasks.values());
  }

  saveTask(task) {
    this.tasks.set(task.id, task);
    if (isSupabaseLive()) {
      TaskRepository.save(task).catch(err => console.error('[Supabase Task Sync Error]:', err.message));
    }
    return task;
  }

  // Fraud showcase helpers
  getShowcase() {
    const fraudOfDay = this.fraudCases.find(c => c.featured === 'day') || null;
    const fraudOfMonth = this.fraudCases.find(c => c.featured === 'month') || null;
    const pastCases = this.fraudCases.filter(c => c.featured !== 'day' && c.featured !== 'month');
    return {
      fraudOfDay,
      fraudOfMonth,
      pastCases,
      allCases: this.fraudCases
    };
  }

  getFraudCase(id) {
    return this.fraudCases.find(c => c.id === id);
  }

  setFraudFeatured(id, featuredType) {
    // If setting a new 'day' or 'month', clear previous ones
    if (featuredType === 'day' || featuredType === 'month') {
      this.fraudCases.forEach(c => {
        if (c.featured === featuredType) c.featured = null;
      });
    }

    const target = this.fraudCases.find(c => c.id === id);
    if (target) {
      target.featured = featuredType;
      if (isSupabaseLive()) {
        FraudRepository.setFeatured(id, featuredType).catch(err => console.error('[Supabase Fraud Sync Error]:', err.message));
      }
      return target;
    }
    return null;
  }
}

export const store = new DataStore();
