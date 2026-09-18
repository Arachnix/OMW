/**
 * Geospatial Algorithms for Campus Routing, Detour & Corridor Matching
 */

/**
 * Calculates Haversine distance between two [lat, lng] points in meters
 */
export function calculateHaversineDistance(coord1, coord2) {
  const [lat1, lon1] = coord1;
  const [lat2, lon2] = coord2;
  const R = 6371e3; // Earth radius in meters
  const toRad = deg => (deg * Math.PI) / 180;

  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return Math.round(R * c);
}

/**
 * Computes bearing (heading in degrees 0-360) from coord1 to coord2
 */
export function calculateBearing(coord1, coord2) {
  const [lat1, lon1] = coord1;
  const [lat2, lon2] = coord2;
  const toRad = deg => (deg * Math.PI) / 180;
  const toDeg = rad => (rad * 180) / Math.PI;

  const y = Math.sin(toRad(lon2 - lon1)) * Math.cos(toRad(lat2));
  const x =
    Math.cos(toRad(lat1)) * Math.sin(toRad(lat2)) -
    Math.sin(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.cos(toRad(lon2 - lon1));

  const bearing = toDeg(Math.atan2(y, x));
  return (bearing + 360) % 360;
}

/**
 * Calculates angular difference in radians between two headings
 */
export function getAngularDifferenceRad(headingA, headingB) {
  let diff = Math.abs(headingA - headingB) % 360;
  if (diff > 180) diff = 360 - diff;
  return (diff * Math.PI) / 180;
}

/**
 * Priority formula from OMW Specification:
 * Priority = (Bounty * Requester Trust Score) / (Distance to Pickup + 0.1 * Detour Distance) * cos(theta)
 */
export function calculateTaskPriority({
  bounty,
  requesterTrustScore = 1.0,
  distanceToPickupMeters,
  detourMeters = 0,
  runnerHeading = 0,
  taskVectorHeading = 0
}) {
  const denominator = Math.max(10, distanceToPickupMeters + 0.1 * detourMeters);
  const theta = getAngularDifferenceRad(runnerHeading, taskVectorHeading);
  // Ensure cos(theta) is non-negative for forward-progress matching (clamped to 0.1 for behind)
  const directionalFactor = Math.max(0.1, Math.cos(theta));

  const priority = ((bounty * requesterTrustScore) / denominator) * directionalFactor * 1000;
  return parseFloat(priority.toFixed(2));
}

/**
 * Finds the closest waypoint along the corridor for a given coordinate
 */
export function findClosestWaypoint(coord, waypoints) {
  let minDistance = Infinity;
  let closestIndex = 0;

  for (let i = 0; i < waypoints.length; i++) {
    const dist = calculateHaversineDistance(coord, waypoints[i]);
    if (dist < minDistance) {
      minDistance = dist;
      closestIndex = i;
    }
  }

  const progressPercent = Math.min(100, Math.round((closestIndex / (waypoints.length - 1)) * 100));
  return {
    index: closestIndex,
    distanceToRouteMeters: minDistance,
    progressPercent
  };
}
