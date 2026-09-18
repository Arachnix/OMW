/**
 * Supabase & Repository Layer Verification Test
 */
import {
  UserRepository,
  WalletRepository,
  TaskRepository,
  MapRepository,
  FraudRepository,
  isSupabaseLive
} from '../src/db/index.js';

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

async function runDbTests() {
  console.log('======================================================');
  console.log('🗄️ Starting OMW Database & Repository Test Suite');
  console.log('======================================================\n');

  console.log(`Database Live Connection Status: ${isSupabaseLive() ? 'SUPABASE_LIVE' : 'HYBRID_FALLBACK'}\n`);

  // 1. User Repository
  console.log('👉 Testing UserRepository:');
  const user = await UserRepository.getById('usr-rohit');
  assert(user && user.name === 'Rohit Verma', 'Successfully resolved user by ID (usr-rohit)');
  assert(user.regNumber === '22BCE1142', 'User reg number matches 22BCE1142');

  const userByReg = await UserRepository.getByRegNumber('22BEE0819');
  assert(userByReg && userByReg.id === 'usr-rohan', 'Successfully resolved runner by registration number');

  const testStudent = await UserRepository.create({
    id: 'usr-test-db',
    name: 'Ananya Sharma',
    regNumber: '22BCE9999',
    regHash: '22BCE****',
    hostelBlock: 'Ladies Hostel D Block',
    trustScore: 5.0,
    completedTasks: 0,
    role: 'student'
  });
  assert(testStudent && testStudent.id === 'usr-test-db', 'Successfully created student profile');

  // 2. Wallet Repository
  console.log('\n👉 Testing WalletRepository:');
  const wallet = await WalletRepository.getByUserId('usr-rohit');
  assert(wallet && typeof wallet.availableTokens === 'number', `Wallet retrieved (Available: ${wallet.availableTokens} tokens)`);

  const newTx = await WalletRepository.addTransaction({
    userId: 'usr-rohit',
    type: 'TOKEN_PURCHASE',
    tokens: 25,
    amountInr: 25,
    reference: 'Test automated token pack top-up'
  });
  assert(newTx && newTx.id, `Transaction recorded successfully (${newTx.id})`);

  const txList = await WalletRepository.getTransactions('usr-rohit', 5);
  assert(Array.isArray(txList) && txList.length > 0, `Transactions history retrieved (${txList.length} items)`);

  // 3. Task Repository
  console.log('\n👉 Testing TaskRepository:');
  const task = await TaskRepository.getById('TSK-101');
  assert(task && task.title.includes('Darling Bakery'), 'Retrieved task TSK-101');
  assert(task.wager === 18, 'Task wager equals 18 tokens');

  const allTasks = await TaskRepository.getAll();
  assert(allTasks.length >= 3, `Retrieved all active campus tasks (Count: ${allTasks.length})`);

  // 4. Map Repository
  console.log('\n👉 Testing MapRepository:');
  const locations = await MapRepository.getAllLocations();
  assert(locations.length === 24, `Retrieved all ${locations.length} VIT landmark nodes`);

  const sjt = await MapRepository.getLocationById('loc-sjt');
  assert(sjt && sjt.name.includes('Silver Jubilee Tower'), 'Retrieved Silver Jubilee Tower landmark');

  // 5. Fraud Repository
  console.log('\n👉 Testing FraudRepository:');
  const showcase = await FraudRepository.getShowcase();
  assert(showcase.fraudOfDay !== null, 'Fraud of the Day case loaded');
  assert(showcase.fraudOfDay.id === 'FRD-2026-089', `Fraud of Day ID: ${showcase.fraudOfDay.id} (${showcase.fraudOfDay.title})`);

  const fraudDetail = await FraudRepository.getById('FRD-2026-089');
  assert(fraudDetail && fraudDetail.user === 'Rahul S.', 'Forensic case details retrieved');
  assert(fraudDetail.evidence && (fraudDetail.evidence.routeDeviation || fraudDetail.evidence.routeDeviationPercent), 'TrustShield route deviation telemetry present');

  console.log('\n======================================================');
  console.log(`📊 DB Test Results: ${passed} Passed, ${failed} Failed`);
  console.log('======================================================\n');

  if (failed > 0) process.exit(1);
}

runDbTests().catch(err => {
  console.error('Fatal DB Test Error:', err);
  process.exit(1);
});
