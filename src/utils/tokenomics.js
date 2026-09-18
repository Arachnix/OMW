/**
 * Tokenomics & Dynamic Pricing Formula (The Smart Slider)
 */

export const TOKEN_EXCHANGE_RATE = 1; // ₹1 INR = 1 OMW Token (Updated)
export const FLOOR_BASE_WAGER = 10;   // 10 Tokens minimum campus baseline
export const RUNNER_STAKE_PERCENT = 0.25; // 25% runner commitment deposit

/**
 * Calculates dynamic baseline wager using OMW formula:
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
