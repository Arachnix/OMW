/**
 * Comprehensive Automated End-to-End API Integration Test Suite for OMW Backend
 */
import { WebSocket } from 'ws';

const BASE_URL = 'http://localhost:3033';
const WS_URL = 'ws://localhost:3033/ws';

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

async function runSuite() {
  console.log('======================================================');
  console.log('🧪 Starting OMW API & Lifecycle Integration Test Suite');
  console.log('======================================================\n');

  try {
    // 1. Healthcheck
    console.log('👉 Testing System Health & Root Metadata:');
    const healthRes = await fetch(`${BASE_URL}/api/health`);
    const healthData = await healthRes.json();
    assert(healthRes.status === 200, 'Health endpoint returns HTTP 200');
    assert(healthData.status === 'online', 'Server reports online status');
    assert(healthData.peggedRate === '1 Token = ₹1 INR', 'Token exchange rate pegged at ₹1/token');

    // 2. Map Endpoints
    console.log('\n👉 Testing GIS Campus Map Endpoints:');
    const locRes = await fetch(`${BASE_URL}/api/map/locations`);
    const locData = await locRes.json();
    assert(locRes.status === 200, 'Locations endpoint returns HTTP 200');
    assert(locData.locations.length === 24, 'All 24 VIT campus landmark nodes returned');

    const corridorRes = await fetch(`${BASE_URL}/api/map/corridor`);
    const corridorData = await corridorRes.json();
    assert(corridorRes.status === 200, 'Corridor endpoint returns HTTP 200');
    assert(corridorData.totalWaypoints === 72, 'Corridor contains 72 physical road GPS waypoints');
    assert(corridorData.turnByTurnCues.length === 6, 'Contains 6-stage turn-by-turn navigation cues');

    const routeCalcRes = await fetch(`${BASE_URL}/api/map/route-calculate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        pickupNodeId: 'loc-main-gate',
        dropNodeId: 'loc-q-block',
        runnerOriginNodeId: 'loc-sjt'
      })
    });
    const routeCalcData = await routeCalcRes.json();
    assert(routeCalcRes.status === 200, 'Route calculator returns HTTP 200');
    assert(routeCalcData.distanceMeters > 0, `Calculated distance: ${routeCalcData.distanceMeters}m`);
    assert(routeCalcData.estimatedWalkMinutes > 0, `Estimated walk time: ${routeCalcData.estimatedWalkMinutes} mins`);

    // 3. Dynamic Wager Calculator ("Smart Slider")
    console.log('\n👉 Testing Dynamic Smart Slider Pricing Calculator:');
    const wagerCalcRes = await fetch(`${BASE_URL}/api/tasks/calculate-wager`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        pickupNodeId: 'loc-tt-xerox',
        dropNodeId: 'loc-sjt',
        urgency: 'urgent',
        isNight: true,
        isRain: false
      })
    });
    const wagerCalcData = await wagerCalcRes.json();
    assert(wagerCalcRes.status === 200, 'Wager calculator returns HTTP 200');
    assert(wagerCalcData.calculation.recommendedWager >= 10, `Recommended wager calculated: ${wagerCalcData.calculation.recommendedWager} tokens`);
    assert(wagerCalcData.calculation.inrValue === wagerCalcData.calculation.recommendedWager * 1, 'INR value reflects ₹1/token peg');

    // 4. Wallet & Razorpay Payment Endpoints
    console.log('\n👉 Testing Wallet & Razorpay Test Payments (pegged at ₹1/token):');
    const balBeforeRes = await fetch(`${BASE_URL}/api/wallet/balance?userId=usr-rohit`);
    const balBeforeData = await balBeforeRes.json();
    const initialTokens = balBeforeData.wallet.availableTokens;
    assert(balBeforeRes.status === 200, `Initial requester balance: ${initialTokens} tokens`);

    // Create Razorpay Order
    const orderRes = await fetch(`${BASE_URL}/api/payments/create-order`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tokenAmount: 50, userId: 'usr-rohit' })
    });
    const orderData = await orderRes.json();
    assert(orderRes.status === 200, 'Razorpay order generated successfully');
    assert(orderData.order.amountInr === 50, '₹50 INR charged for 50 tokens at ₹1/token peg');

    // Verify Payment & Credit Tokens
    const verifyPayRes = await fetch(`${BASE_URL}/api/payments/verify-payment`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        razorpay_order_id: orderData.order.orderId,
        razorpay_payment_id: 'pay_test_simulated_123',
        signature: 'test_mock_signature',
        tokenAmount: 50,
        userId: 'usr-rohit'
      })
    });
    const verifyPayData = await verifyPayRes.json();
    assert(verifyPayRes.status === 200, 'Payment verified and credited');
    assert(verifyPayData.newAvailableBalance === initialTokens + 50, `Balance updated to: ${verifyPayData.newAvailableBalance} tokens`);

    // 5. Task Creation & Escrow Lock
    console.log('\n👉 Testing Task Lifecycle & Escrow Staking:');
    const createTaskRes = await fetch(`${BASE_URL}/api/tasks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: 'Urgent Lab File printout from TT Xerox',
        category: 'academic',
        pickupNodeId: 'loc-tt-xerox',
        dropNodeId: 'loc-sjt',
        wager: 20,
        notes: 'Print double sided on 80gsm bond paper.',
        urgency: 'urgent',
        requesterId: 'usr-rohit'
      })
    });
    const createTaskData = await createTaskRes.json();
    assert(createTaskRes.status === 201, 'Task created with HTTP 201');
    const createdTask = createTaskData.task;
    assert(createdTask.status === 'OPEN', 'Initial task status is OPEN');
    assert(createdTask.pickupOtp && createdTask.deliveryOtp, 'Dual-OTP generated securely');

    // Verify Escrow Lock on Requester Wallet
    const balAfterCreateRes = await fetch(`${BASE_URL}/api/wallet/balance?userId=usr-rohit`);
    const balAfterCreateData = await balAfterCreateRes.json();
    assert(balAfterCreateData.wallet.escrowLocked >= 20, '20 tokens locked into escrow on requester wallet');

    // 6. Task Surging (+5 Tokens)
    console.log('\n👉 Testing Task Visibility Auto-Surge (+5 tokens):');
    const surgeRes = await fetch(`${BASE_URL}/api/tasks/${createdTask.id}/surge`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ surgeTokens: 5 })
    });
    const surgeData = await surgeRes.json();
    assert(surgeRes.status === 200, 'Task surged successfully');
    assert(surgeData.task.wager === 25, `Task wager surged to ${surgeData.task.wager} tokens`);

    // 7. Task Claiming & Runner Commitment Stake (~25%)
    console.log('\n👉 Testing Task Claiming & Runner Stake Deposit:');
    const claimRes = await fetch(`${BASE_URL}/api/tasks/${createdTask.id}/claim`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ runnerId: 'usr-rohan' })
    });
    const claimData = await claimRes.json();
    assert(claimRes.status === 200, 'Task claimed successfully');
    assert(claimData.task.status === 'CLAIMED', 'Status changed to CLAIMED');
    assert(claimData.task.runnerStakeLocked === 6, 'Runner commitment deposit locked (6 tokens)');

    // 8. Pickup Verification (Pickup OTP)
    console.log('\n👉 Testing Source Pickup OTP Handshake:');
    const pickupRes = await fetch(`${BASE_URL}/api/tasks/${createdTask.id}/verify-pickup`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ otp: createdTask.pickupOtp })
    });
    const pickupData = await pickupRes.json();
    assert(pickupRes.status === 200, 'Pickup OTP verified successfully');
    assert(pickupData.task.status === 'IN_TRANSIT', 'Task status transitioned to IN_TRANSIT');

    // 9. Delivery Verification (Delivery OTP) & Atomic Escrow Settlement
    console.log('\n👉 Testing Destination Delivery OTP Handshake & Atomic Payout:');
    const deliveryRes = await fetch(`${BASE_URL}/api/tasks/${createdTask.id}/verify-delivery`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ otp: createdTask.deliveryOtp })
    });
    const deliveryData = await deliveryRes.json();
    assert(deliveryRes.status === 200, 'Delivery OTP verified successfully');
    assert(deliveryData.task.status === 'DELIVERED', 'Task status is DELIVERED');
    assert(deliveryData.settlement.bountyPaid === 25, 'Bounty of 25 tokens transferred to runner');
    assert(deliveryData.settlement.stakeReturned === 6, 'Runner stake of 6 tokens returned');

    // 10. Task Cancellation & Refund Verification
    console.log('\n👉 Testing Task Cancellation & Escrow Refund:');
    const cancelTaskRes = await fetch(`${BASE_URL}/api/tasks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: 'Cancelled Favor Test',
        pickupNodeId: 'loc-gazebo',
        dropNodeId: 'loc-p-block',
        wager: 15,
        requesterId: 'usr-rohit'
      })
    });
    const cancelTaskData = await cancelTaskRes.json();
    const cancelId = cancelTaskData.task.id;

    const cancelActionRes = await fetch(`${BASE_URL}/api/tasks/${cancelId}/cancel`, {
      method: 'POST'
    });
    const cancelActionData = await cancelActionRes.json();
    assert(cancelActionRes.status === 200, 'Task cancelled successfully');
    assert(cancelActionData.task.status === 'CANCELLED', 'Status marked CANCELLED');
    assert(cancelActionData.refund.refundedTokens === 15, 'Full 15 tokens refunded to requester');

    // 11. Spatial Task Priority Feed
    console.log('\n👉 Testing Spatial Priority Task Ranking:');
    const feedRes = await fetch(`${BASE_URL}/api/tasks?runnerLat=12.9695&runnerLng=79.1565&heading=45`);
    const feedData = await feedRes.json();
    assert(feedRes.status === 200, 'Task feed returns HTTP 200');
    assert(feedData.tasks.length > 0, `Feed contains ${feedData.tasks.length} tasks`);
    if (feedData.tasks[0].priorityScore !== undefined) {
      assert(feedData.tasks[0].priorityScore >= (feedData.tasks[1]?.priorityScore || 0), 'Tasks correctly sorted by dynamic spatial corridor priority');
    }

    // 12. TrustShield Showcase & Admin Feature
    console.log('\n👉 Testing TrustShield Showcase & Proctor Feature:');
    const showcaseRes = await fetch(`${BASE_URL}/api/trustshield/showcase`);
    const showcaseData = await showcaseRes.json();
    assert(showcaseRes.status === 200, 'Showcase returns HTTP 200');
    assert(showcaseData.showcase.fraudOfDay !== null, 'Fraud of the Day banner is populated');
    assert(showcaseData.showcase.fraudOfMonth !== null, 'Fraud of the Month showcase is populated');

    // Proctor sets new featured case
    const featureRes = await fetch(`${BASE_URL}/api/trustshield/admin/fraud/FRD-2026-021/feature`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ featured: 'day' })
    });
    const featureData = await featureRes.json();
    assert(featureRes.status === 200, 'Proctor updated Fraud of the Day');
    assert(featureData.case.featured === 'day', 'Target case featured as "day"');

    // 13. Users & Auth Endpoints
    console.log('\n👉 Testing User Profiles & Authentication:');
    const authRes = await fetch(`${BASE_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        regNumber: '23BCE9911',
        name: 'Sneha Patel',
        hostelBlock: 'Ladies Hostel'
      })
    });
    const authData = await authRes.json();
    assert(authRes.status === 200, 'Student authenticated');
    assert(authData.user.regHash === '23BCE****', 'Registration number masked appropriately');

    const profileRes = await fetch(`${BASE_URL}/api/users/usr-rahul`);
    const profileData = await profileRes.json();
    assert(profileRes.status === 200, 'Profile retrieved');
    assert(profileData.profile.isRestricted === true, 'Restricted account notice flag confirmed');

    // 14. Runner Token Cash-Out / Withdrawal
    console.log('\n👉 Testing Runner Earnings Withdrawal:');
    const withdrawRes = await fetch(`${BASE_URL}/api/wallet/withdraw`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: 'usr-rohan',
        tokens: 20,
        method: 'VOUCHER',
        destination: 'Gazebo Food Court Meal Voucher'
      })
    });
    const withdrawData = await withdrawRes.json();
    assert(withdrawRes.status === 200, 'Withdrawal processed');
    assert(withdrawData.inrValue === 20, '₹20 INR value redeemed at ₹1/token exchange rate');

    // 15. WebSocket Live Telemetry Test
    console.log('\n👉 Testing Real-Time WebSocket Connection & Telemetry Stream:');
    await new Promise((resolve, reject) => {
      const ws = new WebSocket(WS_URL);
      const timer = setTimeout(() => {
        ws.close();
        assert(false, 'WebSocket timed out');
        resolve();
      }, 5000);

      ws.on('open', () => {
        assert(true, 'WebSocket client connected to ws://localhost:3033/ws');
        // Send runner GPS location along the corridor
        ws.send(JSON.stringify({
          type: 'RUNNER_LOCATION_UPDATE',
          runnerId: 'usr-rohan',
          lat: 12.9701,
          lng: 79.1594,
          speedKmh: 4.8
        }));
      });

      ws.on('message', data => {
        const msg = JSON.parse(data.toString());
        if (msg.type === 'CONNECTION_ESTABLISHED') {
          assert(true, 'Received WebSocket connection ACK');
        } else if (msg.type === 'RUNNER_LOCATION_BROADCAST') {
          assert(msg.data.runnerId === 'usr-rohan', 'Received live runner location broadcast');
          assert(msg.data.progressPercent >= 0, `Corridor progress calculated: ${msg.data.progressPercent}%`);
          clearTimeout(timer);
          ws.close();
          resolve();
        }
      });

      ws.on('error', err => {
        clearTimeout(timer);
        assert(false, `WebSocket error: ${err.message}`);
        resolve();
      });
    });

    console.log('\n======================================================');
    console.log(`🏁 All tests completed: ${testsPassed} Passed, ${testsFailed} Failed.`);
    console.log('======================================================');

    if (testsFailed > 0) {
      process.exit(1);
    }
  } catch (err) {
    console.error('\n❌ Unhandled error during test run:', err);
    process.exit(1);
  }
}

runSuite();
