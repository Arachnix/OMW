/**
 * GIS Map & Campus Routing Endpoints
 */
import { Router } from 'express';
import { store } from '../data/store.js';
import { CAMPUS_ROAD_WAYPOINTS, CAMPUS_TURN_BY_TURN_CUES } from '../data/campus-data.js';
import { calculateHaversineDistance, calculateBearing } from '../utils/geo.js';

const router = Router();

/**
 * GET /api/map/locations
 * Returns list of 24 high-density campus landmark nodes
 */
router.get('/locations', (req, res) => {
  const { category } = req.query;
  let locations = store.locations;

  if (category) {
    locations = locations.filter(loc => loc.category.toLowerCase() === category.toLowerCase());
  }

  res.json({
    success: true,
    count: locations.length,
    locations
  });
});

/**
 * GET /api/map/corridor
 * Returns 72 road-snapped GPS coordinates from Main Gate to Q Block
 */
router.get('/corridor', (req, res) => {
  res.json({
    success: true,
    name: 'Main Gate Katpadi to Q Block Men\'s Residential Corridor',
    totalWaypoints: CAMPUS_ROAD_WAYPOINTS.length,
    waypoints: CAMPUS_ROAD_WAYPOINTS,
    turnByTurnCues: CAMPUS_TURN_BY_TURN_CUES
  });
});

/**
 * POST /api/map/route-calculate
 * Calculates walking distance, time estimate and detour between nodes
 */
router.post('/route-calculate', (req, res) => {
  const { pickupNodeId, dropNodeId, runnerOriginNodeId } = req.body;

  if (!pickupNodeId || !dropNodeId) {
    return res.status(400).json({
      success: false,
      error: 'Both pickupNodeId and dropNodeId are required'
    });
  }

  const pickupNode = store.getLocationById(pickupNodeId);
  const dropNode = store.getLocationById(dropNodeId);

  if (!pickupNode || !dropNode) {
    return res.status(404).json({
      success: false,
      error: 'One or both landmark nodes could not be found'
    });
  }

  // Straight line distance scaled by 1.3 to approximate paved pedestrian paths
  const directDistance = calculateHaversineDistance(pickupNode.coords, dropNode.coords);
  const estimatedRoadDistance = Math.round(directDistance * 1.3);

  // Average campus walking speed: 4.5 km/h = 75 meters/min
  const estimatedWalkMinutes = Math.max(2, Math.round(estimatedRoadDistance / 75));

  // High-queue spots (TT Xerox, Main Gate food parcel rush)
  let queueTimeMinutes = 2;
  if (pickupNodeId === 'loc-tt-xerox') queueTimeMinutes = 12;
  if (pickupNodeId === 'loc-main-gate') queueTimeMinutes = 8;
  if (pickupNodeId.includes('bakery') || pickupNodeId.includes('gazebo')) queueTimeMinutes = 6;

  let detourMeters = 0;
  if (runnerOriginNodeId) {
    const originNode = store.getLocationById(runnerOriginNodeId);
    if (originNode) {
      const runnerToPickup = calculateHaversineDistance(originNode.coords, pickupNode.coords);
      const runnerToDropDirect = calculateHaversineDistance(originNode.coords, dropNode.coords);
      detourMeters = Math.max(0, (runnerToPickup + directDistance) - runnerToDropDirect);
    }
  }

  const bearing = calculateBearing(pickupNode.coords, dropNode.coords);

  res.json({
    success: true,
    pickupNode: { id: pickupNode.id, name: pickupNode.name, coords: pickupNode.coords },
    dropNode: { id: dropNode.id, name: dropNode.name, coords: dropNode.coords },
    distanceMeters: estimatedRoadDistance,
    estimatedWalkMinutes,
    queueTimeMinutes,
    detourMeters,
    bearing
  });
});

export default router;
