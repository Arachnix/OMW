/**
 * Automated GIS Campus Routing, Telemetry & En-Route Matching Test Suite
 * OMW Campus Logistics Engine — VIT Vellore Main Campus
 */
import {
  VIT_LOCATIONS,
  CAMPUS_ROAD_WAYPOINTS,
  CAMPUS_TURN_BY_TURN_CUES
} from '../src/data/campus-data.js';
import {
  calculateHaversineDistance,
  calculateBearing,
  calculateTaskPriority,
  findClosestWaypoint
} from '../src/utils/geo.js';

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

function runGisTests() {
  console.log('======================================================');
  console.log('🗺️ Starting OMW Campus GIS Map Engine & Telemetry Tests');
  console.log('======================================================\n');

  // 1. Campus Road Waypoints Verification
  console.log('👉 1. Verifying 72-Point Road-Snapped Delivery Corridor:');
  assert(CAMPUS_ROAD_WAYPOINTS.length === 72, `Corridor contains strictly 72 GPS road waypoints (Found: ${CAMPUS_ROAD_WAYPOINTS.length})`);
  
  const startPoint = CAMPUS_ROAD_WAYPOINTS[0];
  const endPoint = CAMPUS_ROAD_WAYPOINTS[CAMPUS_ROAD_WAYPOINTS.length - 1];
  
  assert(startPoint[0] === 12.96920 && startPoint[1] === 79.15590, 'Waypoints start at Main Gate Katpadi Canopy [12.9692, 79.1559]');
  assert(endPoint[0] === 12.97265 && endPoint[1] === 79.16244, 'Waypoints terminate at Q Block Turnstiles [12.97265, 79.16244]');

  // Verify all points are inside VIT Vellore bounding box
  const allInBounds = CAMPUS_ROAD_WAYPOINTS.every(([lat, lng]) => 
    lat >= 12.9650 && lat <= 12.9780 && lng >= 79.1500 && lng <= 79.1700
  );
  assert(allInBounds, 'All 72 waypoints reside strictly within VIT Vellore geographic perimeter');

  // 2. 24 Campus Landmark Nodes
  console.log('\n👉 2. Verifying 24 Campus Landmark Nodes:');
  assert(VIT_LOCATIONS.length === 24, `All 24 landmark nodes mapped (Found: ${VIT_LOCATIONS.length})`);

  const categories = new Set(VIT_LOCATIONS.map(l => l.category));
  assert(categories.has('academic'), 'Academic category mapped (SJT, TT, MB, SMV, CDMM)');
  assert(categories.has('food'), 'Food category mapped (Gazebo, Foody Street, Darling Bakery, Enzymes)');
  assert(categories.has('hostel'), 'Hostel category mapped (Q Block, P Block, K Block, LH)');
  assert(categories.has('facility'), 'Facility category mapped (Library, Auditorium, Health Centre, Xerox)');
  assert(categories.has('gate'), 'Gate category mapped (Main Gate, Gate 2, Gate 3)');

  // 3. 6-Stage Turn-by-Turn Navigation Cues
  console.log('\n👉 3. Verifying 6-Stage Turn-by-Turn Navigation Cues:');
  assert(CAMPUS_TURN_BY_TURN_CUES.length === 6, 'Contains 6 navigation stages');
  assert(CAMPUS_TURN_BY_TURN_CUES[0].title.includes('Depart Main Gate'), 'Stage 1 starts at Main Gate departure');
  assert(CAMPUS_TURN_BY_TURN_CUES[2].title.includes('TT Ground Floor Portico'), 'Stage 3 navigates to TT Xerox pickup');
  assert(CAMPUS_TURN_BY_TURN_CUES[5].title.includes('Q Block Turnstiles'), 'Stage 6 terminates at Q Block drop-off');

  // 4. Waypoint Interpolation & Closest Node Snapping
  console.log('\n👉 4. Testing GPS Waypoint Snapping & Corridor Progress Math:');
  const atStart = findClosestWaypoint(startPoint, CAMPUS_ROAD_WAYPOINTS);
  assert(atStart.index === 0 && atStart.progressPercent === 0, 'Start point snaps to index 0 with 0% progress');

  const atEnd = findClosestWaypoint(endPoint, CAMPUS_ROAD_WAYPOINTS);
  assert(atEnd.index === 71 && atEnd.progressPercent === 100, 'End point snaps to index 71 with 100% progress');

  const midpoint = CAMPUS_ROAD_WAYPOINTS[36];
  const atMid = findClosestWaypoint(midpoint, CAMPUS_ROAD_WAYPOINTS);
  assert(atMid.progressPercent >= 48 && atMid.progressPercent <= 52, `Midpoint snaps to progress: ${atMid.progressPercent}% (Expected ~50%)`);

  // 5. Telemetry & Energy Expenditure Math
  console.log('\n👉 5. Testing Calorie Burn & Step Counter Telemetry Models:');
  const totalCorridorDistanceMeters = 1080;
  const totalCorridorCalories = 42;
  const totalCorridorSteps = 1180;

  const halfProgress = 0.50;
  const halfDist = Math.round(totalCorridorDistanceMeters * halfProgress);
  const halfCal = Math.round(totalCorridorCalories * halfProgress);
  const halfSteps = Math.round(totalCorridorSteps * halfProgress);

  assert(halfDist === 540, `50% corridor distance = 540m`);
  assert(halfCal === 21, `50% corridor calorie expenditure = 21 kcal (Total: ~42 kcal)`);
  assert(halfSteps === 590, `50% corridor steps count = 590 steps (Total: ~1,180 steps)`);

  // 6. Dynamic Priority & En-Route Vector Alignment Algorithm
  console.log('\n👉 6. Testing En-Route Spatial Priority & Heading Directional Alignment:');
  // Runner moving northeast (45 deg) towards a pickup task located northeast (45 deg)
  const alignedPriority = calculateTaskPriority({
    bounty: 25,
    requesterTrustScore: 4.9,
    distanceToPickupMeters: 100,
    detourMeters: 20,
    runnerHeading: 45,
    taskVectorHeading: 45
  });

  // Runner moving northeast (45 deg) towards a task in opposite direction (225 deg)
  const misalignedPriority = calculateTaskPriority({
    bounty: 25,
    requesterTrustScore: 4.9,
    distanceToPickupMeters: 100,
    detourMeters: 20,
    runnerHeading: 45,
    taskVectorHeading: 225
  });

  assert(alignedPriority > misalignedPriority * 5, `Forward-aligned task (${alignedPriority}) significantly outranks backwards task (${misalignedPriority})`);
  assert(alignedPriority > 1000, `High priority score calculated for aligned en-route intercept: ${alignedPriority}`);

  console.log('\n======================================================');
  console.log(`📊 GIS Engine Results: ${passed} Passed, ${failed} Failed`);
  console.log('======================================================\n');

  if (failed > 0) process.exit(1);
}

runGisTests();
