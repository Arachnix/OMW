/**
 * Comprehensive Automated Test Suite for Phase 2: Tokenomics, Escrow Staking & Liquidity Daemon
 * OMW Campus Logistics Engine
 */
import {
  calculateDynamicWager,
  calculateRunnerStake,
  calculateSlashingSplit,
  getNodeQueueEstimate,
  FLOOR_BASE_WAGER,
  STALE_SURGE_THRESHOLD_MINUTES,
  TASK_TTL_MINUTES
} from '../src/utils/tokenomics.js';
import { EscrowService } from '../src/services/escrow/escrowService.js';
import { liquidityDaemon } from '../src/services/escrow/liquidityDaemon.js';
import { store } from '../src/data/store.js';

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

async function runTokenomicsTests() {
  console.log('======================================================');
  console.log('📈 Starting OMW Tokenomics, Escrow & Liquidity Tests');
  console.log('======================================================\n');

  // 1. Dynamic Pricing Smart Slider
  console.log('👉 1. Testing Dynamic Smart Slider Calculations:');
  const normalPricing = calculateDynamicWager({
    distanceMeters: 400,
    queueTimeMinutes: 4,
    urgencyLevel: 'normal',
    isNight: false,
    isRain: false
  });
  // Base 10 + (4 * 2 = 8) + (4 * 0.5 = 2) = 20 tokens
  assert(normalPricing.recommendedWager === 20, `Normal pricing: ${normalPricing.recommendedWager} tokens (Expected 20)`);

  const frictionPricing = calculateDynamicWager({
    distanceMeters: 400,
    queueTimeMinutes: 4,
    urgencyLevel: 'normal',
    isNight: true,
    isRain: true // 1.5x multiplier
  });
  // 20 * 1.5 = 30 tokens
  assert(frictionPricing.recommendedWager === 30, `Friction (night + rain) pricing: ${frictionPricing.recommendedWager} tokens (Expected 30)`);

  const xeroxQueue = getNodeQueueEstimate('loc-tt-xerox');
  assert(xeroxQueue === 12, 'TT Central Xerox has 12-minute peak queue estimate');

  const mainGateQueue = getNodeQueueEstimate('loc-main-gate');
  assert(mainGateQueue === 8, 'Main Gate has 8-minute delivery queue estimate');

  // 2. Anti-Farming Runner Stake Calculation
  console.log('\n👉 2. Testing Runner Commitment Deposit Staking Formula:');
  const stake20 = calculateRunnerStake(20);
  assert(stake20 === 5, `20 token wager requires 5 token runner stake (25%)`);

  const stakeLow = calculateRunnerStake(4);
  assert(stakeLow === 2, `Low wager enforces minimum floor stake of 2 tokens`);

  // 3. Slashing Allocation Split (50/50 Requester Compensation & Platform Burn)
  console.log('\n👉 3. Testing Slashing Split (50% Compensation / 50% Burn):');
  const split6 = calculateSlashingSplit(6);
  assert(split6.requesterCompensation === 3, '3 tokens allocated to requester as compensation');
  assert(split6.platformBurn === 3, '3 tokens allocated to platform burn sink');

  const split5 = calculateSlashingSplit(5);
  assert(split5.requesterCompensation === 2 && split5.platformBurn === 3, 'Odd stake (5) properly splits: 2 to requester, 3 burned');

  // 4. Escrow Staking & Zero-Sum Ledger Invariant
  console.log('\n👉 4. Testing Zero-Sum Ledger Invariant Across Escrow Lifecycle:');
  const reqWallet = store.getWallet('usr-rohit');
  const runWallet = store.getWallet('usr-rohan');

  const initialReqTotal = reqWallet.availableTokens + reqWallet.escrowLocked;
  const initialRunTotal = runWallet.availableTokens + runWallet.runnerStaked;
  const systemInitialTotal = initialReqTotal + initialRunTotal;

  const testTaskId = `TSK-TEST-ECON-${Date.now()}`;
  const testWager = 20;
  const testStake = calculateRunnerStake(testWager); // 5

  // A. Lock Requester Escrow
  await EscrowService.lockRequesterEscrow('usr-rohit', testTaskId, testWager);
  assert(reqWallet.escrowLocked >= testWager, `Requester locked ${testWager} tokens in escrow`);

  // B. Lock Runner Stake
  await EscrowService.lockRunnerStake('usr-rohan', testTaskId, testStake);
  assert(runWallet.runnerStaked >= testStake, `Runner locked ${testStake} tokens commitment deposit`);

  // Verify intermediate invariant
  const intermediateReqTotal = reqWallet.availableTokens + reqWallet.escrowLocked;
  const intermediateRunTotal = runWallet.availableTokens + runWallet.runnerStaked;
  assert(intermediateReqTotal + intermediateRunTotal === systemInitialTotal, 'Zero-Sum Invariant preserved during intermediate lock state');

  // C. Release on Delivery OTP
  const mockTask = {
    id: testTaskId,
    requesterId: 'usr-rohit',
    runnerId: 'usr-rohan',
    wager: testWager,
    runnerStakeLocked: testStake
  };
  const releaseResult = await EscrowService.releaseEscrowOnDelivery(mockTask);

  assert(releaseResult.bountyPaid === testWager, `Bounty of ${testWager} released to runner`);
  assert(releaseResult.stakeReturned === testStake, `Stake of ${testStake} returned to runner`);

  const finalReqTotal = reqWallet.availableTokens + reqWallet.escrowLocked;
  const finalRunTotal = runWallet.availableTokens + runWallet.runnerStaked;
  assert(finalReqTotal + finalRunTotal === systemInitialTotal, 'Zero-Sum Invariant strictly preserved after full delivery settlement');

  // 5. Runner In-Flight Abandonment Slashing Execution
  console.log('\n👉 5. Testing In-Flight Abandonment Slashing:');
  const abandonTaskId = `TSK-ABANDON-${Date.now()}`;
  await EscrowService.lockRequesterEscrow('usr-rohit', abandonTaskId, 20);
  await EscrowService.lockRunnerStake('usr-rohan', abandonTaskId, 6);

  const reqBalBeforeSlash = reqWallet.availableTokens;
  const abandonTask = {
    id: abandonTaskId,
    requesterId: 'usr-rohit',
    runnerId: 'usr-rohan',
    wager: 20,
    runnerStakeLocked: 6
  };

  const slashResult = await EscrowService.slashRunnerStake(abandonTask, 'Pickup timeout exceeded');
  assert(slashResult.slashedAmount === 6, '6 tokens slashed from runner');
  assert(slashResult.requesterCompensation === 3, '3 tokens (50%) credited to requester as compensation');
  assert(reqWallet.availableTokens === reqBalBeforeSlash + 3, 'Requester balance immediately reflects compensation credit');
  assert(slashResult.platformBurn === 3, '3 tokens permanently burned by platform sink');

  // Refund the remaining requester escrow for cleanliness
  await EscrowService.refundEscrowOnCancel(abandonTask);

  // 6. Liquidity Daemon: 10-Minute Stale Task Surge Evaluation
  console.log('\n👉 6. Testing Background Liquidity Daemon (10m Surge & 30m TTL):');
  const staleTaskId = `TSK-STALE-${Date.now()}`;
  const staleTask = {
    id: staleTaskId,
    title: 'Stale Food Delivery',
    category: 'food',
    requesterId: 'usr-rohit',
    wager: 15,
    status: 'OPEN',
    createdAt: new Date(Date.now() - (11 * 60 * 1000)).toISOString(), // 11 mins ago
    surgeActive: false,
    surgeNotified: false
  };
  store.saveTask(staleTask);

  const daemonCycle1 = await liquidityDaemon.runCycle();
  assert(daemonCycle1.staleSurged.includes(staleTaskId), 'Liquidity daemon identified 10-minute stale task and pushed surge prompt');
  assert(staleTask.surgeNotified === true, 'Task flagged as surgeNotified = true to prevent spam notifications');

  // 7. Liquidity Daemon: 30-Minute TTL Auto-Expiry & Refund Evaluation
  const expiredTaskId = `TSK-EXPIRED-${Date.now()}`;
  await EscrowService.lockRequesterEscrow('usr-rohit', expiredTaskId, 15);
  const initialBalBeforeExpiry = reqWallet.availableTokens;

  const expiredTask = {
    id: expiredTaskId,
    title: 'Expired Printout Task',
    category: 'academic',
    requesterId: 'usr-rohit',
    wager: 15,
    status: 'OPEN',
    createdAt: new Date(Date.now() - (32 * 60 * 1000)).toISOString(), // 32 mins ago
    surgeActive: false
  };
  store.saveTask(expiredTask);

  const daemonCycle2 = await liquidityDaemon.runCycle();
  assert(daemonCycle2.ttlExpired.includes(expiredTaskId), 'Liquidity daemon identified 30-minute TTL expired task');
  assert(expiredTask.status === 'EXPIRED', 'Task status transitioned to EXPIRED');
  assert(reqWallet.availableTokens >= initialBalBeforeExpiry + 15, '100% escrow automatically refunded to requester wallet');

  console.log('\n======================================================');
  console.log(`📊 Tokenomics & Escrow Results: ${passed} Passed, ${failed} Failed`);
  console.log('======================================================\n');

  if (failed > 0) process.exit(1);
}

runTokenomicsTests().catch(err => {
  console.error('Fatal Tokenomics Test Error:', err);
  process.exit(1);
});
