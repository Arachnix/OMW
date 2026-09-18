/**
 * Tokenomics, Dynamic Pricing Formula & Economic Invariants
 * OMW Campus Logistics Engine
 */

export const TOKEN_EXCHANGE_RATE = 1; // ₹1 INR = 1 OMW Token
export const FLOOR_BASE_WAGER = 10;   // 10 Tokens minimum campus baseline
export const RUNNER_STAKE_PERCENT = 0.25; // 25% runner commitment deposit
export const TASK_TTL_MINUTES = 30;   // 30 Minutes Time-To-Live before auto-refund
export const STALE_SURGE_THRESHOLD_MINUTES = 10; // 10 Minutes unaccepted trigger
export const STALE_SURGE_INCREMENT = 5; // +5 Tokens visibility surge boost
export const PICKUP_TIMEOUT_MINUTES = 15; // 15 Minutes pickup grace period before abandonment
export const SLASH_COMPENSATION_RATIO = 0.50; // 50% to requester, 50% burned

/**
 * Historical queue delays at high-density VIT Vellore choke points (in minutes)
 */
export const CAMPUS_NODE_QUEUE_ESTIMATES = {
  'loc-tt-xerox': 12,       // Lab report printing & binding queue
  'loc-main-gate': 8,        // Security gate parcel delivery crowd
  'loc-post-office': 10,     // Speed post & courier counter line
  'loc-gazebo': 6,           // Juice bar & evening snack counters
  'loc-darling-bakery': 6,   // Fresh bakery & cold coffee rush
  'loc-all-mart': 5,         // Supermarket billing counter
  'loc-enzymes': 5           // Canteen rush hours
};

/**
 * Resolves estimated queue friction delay for a campus location
 */
export function getNodeQueueEstimate(nodeId) {
  if (!nodeId) return 3;
  return CAMPUS_NODE_QUEUE_ESTIMATES[nodeId] || 3;
}

/**
 * Calculates dynamic baseline wager using OMW Smart Slider formula:
 * Wager = [Base + (Distance_units * 2) + (Queue_Time * 0.5)] * Urgency * Friction
 * 
 * distanceMeters: road distance in meters (each 100m adds 2 tokens)
 * queueTimeMinutes: expected queue delay in minutes (each minute adds 0.5 tokens)
 * urgencyLevel: 'normal' (1.0), 'urgent' (1.25), 'critical' (1.5)
 * friction: { isNight: boolean, isRain: boolean }
 */
export function calculateDynamicWager({
  distanceMeters = 300,
  queueTimeMinutes = 5,
  urgencyLevel = 'normal',
  isNight = false,
  isRain = false
}) {
  const base = FLOOR_BASE_WAGER;
  
  // Distance factor: 1 unit per 100m, capped at realistic campus distances
  const distanceUnits = Math.max(1, distanceMeters / 100);
  const distanceTokens = parseFloat((distanceUnits * 2).toFixed(1));

  // Queue time factor: 0.5 tokens per minute
  const queueTokens = parseFloat((queueTimeMinutes * 0.5).toFixed(1));

  // Urgency multiplier
  let urgencyMultiplier = 1.0;
  if (urgencyLevel === 'urgent') urgencyMultiplier = 1.25;
  if (urgencyLevel === 'critical') urgencyMultiplier = 1.5;

  // Friction multiplier (Night delivery / Weather conditions: 1.25x - 1.5x)
  let frictionMultiplier = 1.0;
  if (isNight && isRain) {
    frictionMultiplier = 1.5;
  } else if (isNight || isRain) {
    frictionMultiplier = 1.25;
  }

  const rawWager = (base + distanceTokens + queueTokens) * urgencyMultiplier * frictionMultiplier;
  const recommendedWager = Math.max(FLOOR_BASE_WAGER, Math.round(rawWager));

  return {
    baseWager: base,
    distanceTokens,
    queueTokens,
    urgencyMultiplier,
    frictionMultiplier,
    recommendedWager,
    inrValue: recommendedWager * TOKEN_EXCHANGE_RATE
  };
}

/**
 * Computes runner stake deposit required to claim task (~25% of bounty)
 */
export function calculateRunnerStake(wager) {
  return Math.max(2, Math.round(wager * RUNNER_STAKE_PERCENT));
}

/**
 * Calculates allocation of slashed stake:
 * 50% credited to inconvenienced requester as compensation, 50% burned by platform sink
 */
export function calculateSlashingSplit(stakedAmount) {
  const compensation = Math.floor(stakedAmount * SLASH_COMPENSATION_RATIO);
  const burned = stakedAmount - compensation;
  return {
    totalSlashed: stakedAmount,
    requesterCompensation: compensation,
    platformBurn: burned
  };
}
