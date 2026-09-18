/**
 * Automated Verification Suite for Google OAuth, VIT Student Email Parser & Promotional Airdrop
 */
import { parseVitEmail, calculateAcademicStanding } from '../src/utils/vitAuth.js';
import { store } from '../src/data/store.js';
import { PaymentService } from '../src/services/payment/paymentService.js';
import { EscrowService } from '../src/services/escrow/escrowService.js';

let testsPassed = 0;
let testsFailed = 0;

function assert(condition, message) {
  if (condition) {
    console.log(`  ✓ ${message}`);
    testsPassed++;
  } else {
    console.error(`  ✗ FAIL: ${message}`);
    testsFailed++;
  }
}

async function runAuthSuite() {
  console.log('======================================================');
  console.log('🎓 Starting Google OAuth, VIT Email & Airdrop Tests');
  console.log('======================================================\n');

  // 1. Email Parsing & Academic Standing
  console.log('👉 1. Testing VIT Email Domain Parser:');
  const targetEmail = 'vismay.shrouty2025@vitstudent.ac.in';
  const parsed = parseVitEmail(targetEmail);

  assert(parsed.isValidVit === true, 'Recognized official @vitstudent.ac.in domain');
  assert(parsed.firstName === 'Vismay', `Extracted first name: '${parsed.firstName}' (Expected: Vismay)`);
  assert(parsed.lastName === 'Shrouty', `Extracted surname: '${parsed.lastName}' (Expected: Shrouty)`);
  assert(parsed.fullName === 'Vismay Shrouty', `Formatted full name: '${parsed.fullName}'`);
  assert(parsed.admissionYear === 2025, `Extracted admission year: ${parsed.admissionYear}`);
  assert(parsed.academicStanding === '2nd Year (Sophomore)', `Computed academic standing: '${parsed.academicStanding}'`);
  assert(parsed.academicYearNumber === 2, 'Computed year number: 2');

  // 2. Batch Standing Calculations
  console.log('\n👉 2. Testing Academic Standing Calculations across Batches:');
  const standing2026 = calculateAcademicStanding(2026, 2026);
  assert(standing2026.label === '1st Year (Freshman)', '2026 admission = 1st Year (Freshman)');

  const standing2025 = calculateAcademicStanding(2025, 2026);
  assert(standing2025.label === '2nd Year (Sophomore)', '2025 admission = 2nd Year (Sophomore)');

  const standing2024 = calculateAcademicStanding(2024, 2026);
  assert(standing2024.label === '3rd Year (Junior)', '2024 admission = 3rd Year (Junior)');

  const standing2023 = calculateAcademicStanding(2023, 2026);
  assert(standing2023.label === '4th Year (Senior)', '2023 admission = 4th Year (Senior)');

  // 3. Strict Domain Guardrails (Rejection of non-VIT emails)
  console.log('\n👉 3. Testing Domain Guardrails:');
  const gmailCheck = parseVitEmail('vismay@gmail.com');
  assert(gmailCheck.isValidVit === false, 'Rejected non-VIT domain @gmail.com');
  assert(gmailCheck.error.includes('Only verified VIT students'), 'Appropriate domain restriction error returned');

  const srmCheck = parseVitEmail('student@srmist.edu.in');
  assert(srmCheck.isValidVit === false, 'Rejected non-VIT university domain @srmist.edu.in');

  // 4. User Registration with 20 Welcome Airdrop Tokens
  console.log('\n👉 4. Testing Google Sign-In & 20-Token Welcome Airdrop:');
  const testUserId = `usr-test-${Date.now()}`;
  const newUser = store.createUser({
    id: testUserId,
    name: parsed.fullName,
    email: parsed.email,
    admissionYear: parsed.admissionYear,
    academicStanding: parsed.academicStanding,
    regNumber: '25BCE9911',
    regHash: '25BCE****',
    hostelBlock: 'Q Block',
    trustScore: 5.0,
    completedTasks: 0,
    isRestricted: false,
    role: 'student'
  }, 20); // 20 tokens airdrop

  const wallet = store.getWallet(testUserId);
  assert(wallet.availableTokens === 20, `Wallet has 20 total available tokens (Found: ${wallet.availableTokens})`);
  assert(wallet.bonusTokens === 20, `Wallet has 20 non-cashable bonus tokens (Found: ${wallet.bonusTokens})`);
  assert(wallet.cashableTokens === 0, `Wallet has 0 cashable tokens (Found: ${wallet.cashableTokens})`);

  const txs = store.getTransactions(testUserId);
  const airdropTx = txs.find(t => t.type === 'AIRDROP_BONUS');
  assert(airdropTx !== undefined, 'AIRDROP_BONUS transaction recorded in financial ledger');
  assert(airdropTx.tokens === 20, 'Airdrop transaction recorded 20 tokens');

  // 5. Non-Cashable Protection (Preventing Fiat Drain of Promo Tokens)
  console.log('\n👉 5. Testing Cashout Protection for Promotional Tokens:');
  let cashoutBlocked = false;
  try {
    await PaymentService.processFiatCashout({
      userId: testUserId,
      tokens: 10,
      method: 'UPI',
      destination: 'vismay@okaxis'
    });
  } catch (err) {
    cashoutBlocked = true;
    assert(err.message.includes('Cannot cash out promotional tokens'), `Cashout correctly rejected with: '${err.message}'`);
  }
  assert(cashoutBlocked === true, 'Protected against cashing out non-cashable airdrop tokens to fiat');

  // 6. Spending Bonus Tokens to Fund Campus Microgigs
  console.log('\n👉 6. Testing Spending Promotional Tokens on Microgig Escrow:');
  const taskId = `TSK-AIRDROP-${Date.now()}`;
  const lockResult = await EscrowService.lockTaskEscrow(testUserId, taskId, 15);

  assert(lockResult.lockedAmount === 15, '15 tokens locked into escrow for task');
  assert(wallet.bonusTokens === 5, `Bonus balance deducted from 20 -> 5 (Found: ${wallet.bonusTokens})`);
  assert(wallet.availableTokens === 5, `Available balance updated to 5 (Found: ${wallet.availableTokens})`);
  assert(wallet.escrowLocked === 15, `Escrow locked updated to 15 (Found: ${wallet.escrowLocked})`);

  // 7. Runner Settlement Converts Bounty to Cashable Tokens
  console.log('\n👉 7. Testing Runner Bounty Conversion to Cashable Tokens:');
  const runnerId = 'usr-rohan';
  const runnerWallet = store.getWallet(runnerId);
  const initialRunnerCashable = runnerWallet.cashableTokens || runnerWallet.availableTokens;

  const mockTask = {
    id: taskId,
    requesterId: testUserId,
    runnerId: runnerId,
    wager: 15,
    runnerStakeLocked: 4
  };

  runnerWallet.runnerStaked = 4;
  await EscrowService.releaseEscrowOnDelivery(mockTask);

  assert(runnerWallet.cashableTokens >= initialRunnerCashable + 15, 'Runner received 15 earned tokens as cashable balance');

  // Runner can withdraw earned tokens
  const cashoutResult = await PaymentService.processFiatCashout({
    userId: runnerId,
    tokens: 15,
    method: 'UPI',
    destination: 'rohan@oksbi'
  });
  assert(cashoutResult.success === true, 'Runner successfully cashed out earned tokens to UPI');
  assert(cashoutResult.withdrawnTokens === 15, '15 tokens redeemed to fiat ₹15 INR');

  console.log('\n======================================================');
  console.log(`📊 Auth & Airdrop Results: ${testsPassed} Passed, ${testsFailed} Failed`);
  console.log('======================================================\n');

  if (testsFailed > 0) process.exit(1);
}

runAuthSuite().catch(err => {
  console.error('Test Suite Error:', err);
  process.exit(1);
});
