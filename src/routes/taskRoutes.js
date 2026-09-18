/**
 * Task Marketplace & Lifecycle Endpoints
 */
import { Router } from 'express';
import { store } from '../data/store.js';
import { calculateDynamicWager, calculateRunnerStake } from '../utils/tokenomics.js';
import { calculateTaskPriority, calculateHaversineDistance, calculateBearing } from '../utils/geo.js';
import { generateOtp } from '../utils/crypto.js';
import { EscrowService } from '../services/escrow/escrowService.js';
import { socketService } from '../services/socket/socketService.js';

const router = Router();

/**
 * POST /api/tasks/calculate-wager
 * Smart Slider Dynamic Pricing Baseline Calculator
 */
router.post('/calculate-wager', (req, res) => {
  const {
    pickupNodeId,
    dropNodeId,
    urgency = 'normal',
    isNight = false,
    isRain = false
  } = req.body;

  let distanceMeters = 350;
  let queueTimeMinutes = 4;

  if (pickupNodeId && dropNodeId) {
    const pickup = store.getLocationById(pickupNodeId);
    const drop = store.getLocationById(dropNodeId);
    if (pickup && drop) {
      distanceMeters = Math.round(calculateHaversineDistance(pickup.coords, drop.coords) * 1.3);
      if (pickupNodeId === 'loc-tt-xerox') queueTimeMinutes = 12;
      if (pickupNodeId === 'loc-main-gate') queueTimeMinutes = 8;
      if (pickupNodeId.includes('bakery') || pickupNodeId.includes('gazebo')) queueTimeMinutes = 6;
    }
  }

  const calculation = calculateDynamicWager({
    distanceMeters,
    queueTimeMinutes,
    urgencyLevel: urgency,
    isNight,
    isRain
  });

  const runnerStake = calculateRunnerStake(calculation.recommendedWager);

  res.json({
    success: true,
    calculation: {
      ...calculation,
      distanceMeters,
      queueTimeMinutes,
      runnerStakeRequired: runnerStake
    }
  });
});

/**
 * POST /api/tasks
 * Create a new task (locks 100% tokens in escrow)
 */
router.post('/', async (req, res) => {
  const {
    title,
    category = 'general',
    pickupNodeId,
    dropNodeId,
    wager,
    notes = '',
    urgency = 'normal',
    requesterId = 'usr-rohit'
  } = req.body;

  if (!title || !pickupNodeId || !dropNodeId) {
    return res.status(400).json({
      success: false,
      error: 'Missing required fields: title, pickupNodeId, and dropNodeId are required'
    });
  }

  const pickupNode = store.getLocationById(pickupNodeId);
  const dropNode = store.getLocationById(dropNodeId);

  if (!pickupNode || !dropNode) {
    return res.status(404).json({
      success: false,
      error: 'Invalid pickup or drop landmark node ID'
    });
  }

  const requester = store.getUser(requesterId) || {
    id: requesterId,
    name: 'Student Requester',
    trustScore: 4.8
  };

  const finalWager = Number(wager) || 15;
  const taskId = `TSK-${Date.now().toString().slice(-4)}`;
  const now = Date.now();

  try {
    // 1. Lock 100% wager into escrow
    await EscrowService.lockRequesterEscrow(requesterId, taskId, finalWager);

    const newTask = {
      id: taskId,
      title,
      category,
      requesterId,
      requesterName: requester.name,
      requesterTrustScore: requester.trustScore,
      pickupNodeId,
      pickupNodeName: pickupNode.name,
      pickupCoords: pickupNode.coords,
      dropNodeId,
      dropNodeName: dropNode.name,
      dropCoords: dropNode.coords,
      wager: finalWager,
      notes,
      urgency,
      status: 'OPEN',
      runnerId: null,
      runnerName: null,
      pickupOtp: generateOtp(),
      deliveryOtp: generateOtp(),
      runnerStakeLocked: 0,
      createdAt: new Date(now).toISOString(),
      expiresAt: new Date(now + 30 * 60 * 1000).toISOString(), // 30m TTL
      surgeActive: false,
      surgeNotified: false
    };

    store.saveTask(newTask);

    // Notify via WebSocket
    socketService.broadcastTaskStateChange(newTask, requesterId);
    socketService.broadcastEnRouteAlert(newTask);

    res.status(201).json({
      success: true,
      message: 'Task published successfully and tokens locked in escrow',
      task: newTask
    });
  } catch (err) {
    return res.status(400).json({
      success: false,
      error: err.message
    });
  }
});

/**
 * GET /api/tasks
 * Feed of tasks with spatial corridor ranking
 */
router.get('/', (req, res) => {
  const { status, runnerLat, runnerLng, heading = 0 } = req.query;
  let tasks = store.getAllTasks();

  if (status) {
    tasks = tasks.filter(t => t.status.toLowerCase() === status.toLowerCase());
  }

  // If runner GPS coordinates are provided, compute spatial vector priority
  if (runnerLat !== undefined && runnerLng !== undefined) {
    const runnerCoord = [parseFloat(runnerLat), parseFloat(runnerLng)];
    const rHeading = parseFloat(heading);

    tasks = tasks.map(task => {
      const distToPickup = calculateHaversineDistance(runnerCoord, task.pickupCoords);
      const taskVectorHeading = calculateBearing(task.pickupCoords, task.dropCoords);
      const priorityScore = calculateTaskPriority({
        bounty: task.wager,
        requesterTrustScore: task.requesterTrustScore,
        distanceToPickupMeters: distToPickup,
        detourMeters: 50,
        runnerHeading: rHeading,
        taskVectorHeading
      });

      return {
        ...task,
        distanceToPickupMeters: distToPickup,
        priorityScore
      };
    });

    // Rank highest priority first
    tasks.sort((a, b) => (b.priorityScore || 0) - (a.priorityScore || 0));
  } else {
    // Default sorting: open first, then newest
    tasks.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  }

  res.json({
    success: true,
    count: tasks.length,
    tasks
  });
});

/**
 * GET /api/tasks/:id
 * Retrieve single task details
 */
router.get('/:id', (req, res) => {
  const task = store.getTask(req.params.id);
  if (!task) {
    return res.status(404).json({ success: false, error: 'Task not found' });
  }

  res.json({
    success: true,
    task
  });
});

/**
 * POST /api/tasks/:id/claim
 * Runner claims task and locks ~25% stake deposit
 */
router.post('/:id/claim', async (req, res) => {
  const { runnerId = 'usr-rohan' } = req.body;
  const task = store.getTask(req.params.id);

  if (!task) {
    return res.status(404).json({ success: false, error: 'Task not found' });
  }

  if (task.status !== 'OPEN') {
    return res.status(400).json({
      success: false,
      error: `Task cannot be claimed. Current status is ${task.status}`
    });
  }

  if (task.requesterId === runnerId) {
    return res.status(400).json({
      success: false,
      error: 'Requester cannot claim their own task'
    });
  }

  const runner = store.getUser(runnerId) || { id: runnerId, name: 'Campus Runner' };
  const stakeRequired = calculateRunnerStake(task.wager);

  try {
    // Lock runner stake
    await EscrowService.lockRunnerStake(runnerId, task.id, stakeRequired);

    task.status = 'CLAIMED';
    task.runnerId = runnerId;
    task.runnerName = runner.name;
    task.runnerStakeLocked = stakeRequired;
    task.claimedAt = new Date().toISOString();

    store.saveTask(task);
    socketService.broadcastTaskStateChange(task, runnerId);

    res.json({
      success: true,
      message: 'Task claimed successfully and runner commitment deposit locked',
      task: {
        ...task,
        pickupOtp: task.pickupOtp // Provided so runner can inspect during handoff
      }
    });
  } catch (err) {
    return res.status(400).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/tasks/:id/verify-pickup
 * Runner verifies Pickup OTP at package pickup source
 */
router.post('/:id/verify-pickup', (req, res) => {
  const { otp } = req.body;
  const task = store.getTask(req.params.id);

  if (!task) {
    return res.status(404).json({ success: false, error: 'Task not found' });
  }

  if (task.status !== 'CLAIMED') {
    return res.status(400).json({
      success: false,
      error: `Pickup verification invalid for task in ${task.status} status`
    });
  }

  if (task.pickupOtp !== String(otp).trim()) {
    return res.status(400).json({
      success: false,
      error: 'Invalid Pickup OTP. Please confirm with counter staff or pickup contact.'
    });
  }

  task.status = 'IN_TRANSIT';
  task.pickedUpAt = new Date().toISOString();
  store.saveTask(task);

  socketService.broadcastTaskStateChange(task, task.runnerId);

  res.json({
    success: true,
    message: 'Pickup OTP verified! Custody accepted and task marked IN_TRANSIT',
    task
  });
});

/**
 * POST /api/tasks/:id/verify-delivery
 * Requester or Runner verifies Delivery OTP at drop-off; atomically releases tokens
 */
router.post('/:id/verify-delivery', async (req, res) => {
  const { otp } = req.body;
  const task = store.getTask(req.params.id);

  if (!task) {
    return res.status(404).json({ success: false, error: 'Task not found' });
  }

  if (task.status !== 'IN_TRANSIT' && task.status !== 'CLAIMED') {
    return res.status(400).json({
      success: false,
      error: `Delivery verification invalid for task in ${task.status} status`
    });
  }

  if (task.deliveryOtp !== String(otp).trim()) {
    return res.status(400).json({
      success: false,
      error: 'Invalid Delivery OTP provided by recipient'
    });
  }

  try {
    // Release escrow and return stake
    const escrowResult = await EscrowService.releaseEscrowOnDelivery(task);

    task.status = 'DELIVERED';
    task.deliveredAt = new Date().toISOString();
    store.saveTask(task);

    // Update completed counts
    const runner = store.getUser(task.runnerId);
    if (runner) runner.completedTasks = (runner.completedTasks || 0) + 1;

    socketService.broadcastTaskStateChange(task, task.runnerId);

    res.json({
      success: true,
      message: 'Delivery OTP verified successfully! Bounty released and stake returned.',
      task,
      settlement: escrowResult
    });
  } catch (err) {
    return res.status(400).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/tasks/:id/surge
 * Adds +5 tokens auto-surge prompt or manual boost
 */
router.post('/:id/surge', async (req, res) => {
  const { surgeTokens = 5 } = req.body;
  const task = store.getTask(req.params.id);

  if (!task) {
    return res.status(404).json({ success: false, error: 'Task not found' });
  }

  if (task.status !== 'OPEN') {
    return res.status(400).json({
      success: false,
      error: 'Cannot surge a task that is not OPEN'
    });
  }

  try {
    // Lock additional tokens in escrow
    await EscrowService.lockRequesterEscrow(task.requesterId, task.id, Number(surgeTokens));

    task.wager += Number(surgeTokens);
    task.surgeActive = true;
    store.saveTask(task);

    socketService.broadcastTaskStateChange(task, task.requesterId);

    res.json({
      success: true,
      message: `Surged task by +${surgeTokens} tokens to boost visibility`,
      task
    });
  } catch (err) {
    return res.status(400).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/tasks/:id/cancel
 * Cancel open task and refund locked escrow
 */
router.post('/:id/cancel', async (req, res) => {
  const task = store.getTask(req.params.id);

  if (!task) {
    return res.status(404).json({ success: false, error: 'Task not found' });
  }

  if (task.status !== 'OPEN') {
    return res.status(400).json({
      success: false,
      error: `Cannot cancel task in status ${task.status}`
    });
  }

  try {
    const refund = await EscrowService.refundEscrowOnCancel(task);
    task.status = 'CANCELLED';
    task.cancelledAt = new Date().toISOString();
    store.saveTask(task);

    socketService.broadcastTaskStateChange(task, task.requesterId);

    res.json({
      success: true,
      message: 'Task cancelled and escrow refunded to requester',
      task,
      refund
    });
  } catch (err) {
    return res.status(400).json({ success: false, error: err.message });
  }
});

export default router;
