/**
 * Campus Geographic Coordinates, Waypoints & Fraud Data for VIT Vellore Main Campus
 */

export const VIT_LOCATIONS = [
  { id: 'loc-main-gate', name: 'Main Gate Katpadi Entrance', category: 'gate', color: '#334155', coords: [12.9692, 79.1559] },
  { id: 'loc-gate-2', name: 'Gate 2 (Chittoor Bus Stand Road)', category: 'gate', color: '#334155', coords: [12.9734, 79.1637] },
  { id: 'loc-gate-3', name: 'Gate 3 (Railway Side Entrance)', category: 'gate', color: '#334155', coords: [12.9680, 79.1585] },
  { id: 'loc-sjt', name: 'Silver Jubilee Tower (SJT)', category: 'academic', color: '#2563eb', coords: [12.9710, 79.1635] },
  { id: 'loc-tt', name: 'Technology Tower (TT) & Portico', category: 'academic', color: '#2563eb', coords: [12.9702, 79.1594] },
  { id: 'loc-tt-xerox', name: 'TT Ground Floor Central Xerox', category: 'facility', color: '#475569', coords: [12.9701, 79.1592] },
  { id: 'loc-mb', name: 'Main Building (Dr. MGR Block)', category: 'academic', color: '#2563eb', coords: [12.9696, 79.1578] },
  { id: 'loc-smv', name: 'SMV Engineering Block', category: 'academic', color: '#2563eb', coords: [12.9699, 79.1583] },
  { id: 'loc-cdmm', name: 'CDMM Mechanical Block', category: 'academic', color: '#2563eb', coords: [12.9694, 79.1599] },
  { id: 'loc-anna-audi', name: 'Anna Auditorium Hexagon', category: 'facility', color: '#475569', coords: [12.9698, 79.1568] },
  { id: 'loc-periyar-lib', name: 'Periyar Central Library', category: 'academic', color: '#2563eb', coords: [12.9695, 79.1564] },
  { id: 'loc-gazebo', name: 'Gazebo Food Court & Juice Bar', category: 'food', color: '#d97706', coords: [12.9705, 79.1601] },
  { id: 'loc-foody-st', name: 'Foody Street Campus Boulevard', category: 'food', color: '#d97706', coords: [12.9707, 79.1608] },
  { id: 'loc-darling-bakery', name: 'Darling Bakery & Coffee Portico', category: 'food', color: '#d97706', coords: [12.9698, 79.1588] },
  { id: 'loc-enzymes', name: 'Enzymes Canteen (Near SJT)', category: 'food', color: '#d97706', coords: [12.9713, 79.1630] },
  { id: 'loc-health-centre', name: 'VIT Central Health Centre & Pharmacy', category: 'facility', color: '#475569', coords: [12.9712, 79.1614] },
  { id: 'loc-swimming-pool', name: 'Olympic Sports Complex & Pool', category: 'facility', color: '#475569', coords: [12.9720, 79.1610] },
  { id: 'loc-p-block', name: 'P Block Men\'s Hostel', category: 'hostel', color: '#0d9488', coords: [12.9718, 79.1619] },
  { id: 'loc-q-block', name: 'Q Block Men\'s Residential Tower', category: 'hostel', color: '#0d9488', coords: [12.9726, 79.1624] },
  { id: 'loc-k-block', name: 'K Block Men\'s Hostel', category: 'hostel', color: '#0d9488', coords: [12.9709, 79.1622] },
  { id: 'loc-l-block', name: 'L Block Men\'s Hostel', category: 'hostel', color: '#0d9488', coords: [12.9714, 79.1625] },
  { id: 'loc-ladies-hostel', name: 'LH Central Security Turnstile', category: 'hostel', color: '#0d9488', coords: [12.9687, 79.1575] },
  { id: 'loc-all-mart', name: 'All Mart Campus Supermarket', category: 'facility', color: '#475569', coords: [12.9710, 79.1617] },
  { id: 'loc-post-office', name: 'Campus Post Office & SBI Bank', category: 'facility', color: '#475569', coords: [12.9691, 79.1568] }
];

// 72-Point Road-Snapped Delivery Corridor (Main Gate -> Q Block)
export const CAMPUS_ROAD_WAYPOINTS = [
  [12.96920, 79.15590], [12.96924, 79.15600], [12.96928, 79.15610], [12.96932, 79.15620],
  [12.96936, 79.15630], [12.96940, 79.15638], [12.96944, 79.15645], [12.96948, 79.15652],
  [12.96952, 79.15660], [12.96956, 79.15668], [12.96960, 79.15675], [12.96965, 79.15682],
  [12.96970, 79.15688], [12.96975, 79.15694], [12.96980, 79.15700], [12.96983, 79.15708],
  [12.96986, 79.15718], [12.96988, 79.15730], [12.96990, 79.15745], [12.96991, 79.15760],
  [12.96992, 79.15775], [12.96993, 79.15790], [12.96994, 79.15805], [12.96995, 79.15820],
  [12.96996, 79.15835], [12.96997, 79.15850], [12.96998, 79.15865], [12.97000, 79.15880],
  [12.97002, 79.15895], [12.97004, 79.15910], [12.97006, 79.15920], [12.97008, 79.15930],
  [12.97010, 79.15940], [12.97013, 79.15948], [12.97016, 79.15956], [12.97020, 79.15965],
  [12.97025, 79.15975], [12.97030, 79.15985], [12.97035, 79.15995], [12.97040, 79.16005],
  [12.97045, 79.16015], [12.97050, 79.16025], [12.97055, 79.16035], [12.97060, 79.16045],
  [12.97064, 79.16055], [12.97068, 79.16065], [12.97072, 79.16075], [12.97076, 79.16085],
  [12.97080, 79.16095], [12.97085, 79.16105], [12.97090, 79.16115], [12.97095, 79.16125],
  [12.97100, 79.16135], [12.97105, 79.16145], [12.97110, 79.16155], [12.97115, 79.16165],
  [12.97120, 79.16175], [12.97128, 79.16182], [12.97136, 79.16189], [12.97145, 79.16196],
  [12.97155, 79.16203], [12.97165, 79.16210], [12.97178, 79.16216], [12.97190, 79.16222],
  [12.97202, 79.16227], [12.97214, 79.16231], [12.97226, 79.16235], [12.97238, 79.16238],
  [12.97248, 79.16240], [12.97255, 79.16242], [12.97260, 79.16243], [12.97265, 79.16244]
];

export const CAMPUS_TURN_BY_TURN_CUES = [
  { stage: 1, title: 'Depart Main Gate Katpadi Canopy', distanceMeters: 180, instruction: 'Head northeast along Periyar Library Avenue toward Central Circle.' },
  { stage: 2, title: 'Pass Anna Auditorium Hexagon', distanceMeters: 220, instruction: 'Continue past Dr. MGR Main Building onto Central Boulevard.' },
  { stage: 3, title: 'Arrive at TT Ground Floor Portico', distanceMeters: 160, instruction: 'Turn right at Technology Tower portico for Xerox pick-up.' },
  { stage: 4, title: 'Cross Gazebo & Foody Street Walkway', distanceMeters: 210, instruction: 'Follow the pedestrian avenue past Gazebo towards Health Centre.' },
  { stage: 5, title: 'Pass Health Centre & P Block', distanceMeters: 190, instruction: 'Take the residential corridor heading north between P and L blocks.' },
  { stage: 6, title: 'Arrive at Q Block Turnstiles', distanceMeters: 120, instruction: 'Terminus at Q Block Men\'s Residential entrance for Delivery OTP handshake.' }
];

export const INITIAL_FRAUD_CASES = [
  {
    id: 'FRD-2026-089',
    user: 'Rahul S.',
    regHash: '22BCE****',
    title: 'The Great Pizza Phantom Hand-off',
    summary: 'Courier recorded simultaneous pickup at Main Gate and drop at Q Block within 12 seconds.',
    status: 'CONFIRMED VIOLATION',
    featured: 'day',
    violationType: 'IMPOSSIBLE_VELOCITY_TELEMETRY',
    microcopy: 'OMW remembers. Not the route we recommended.',
    evidence: {
      routeDeviation: 'Crossed 1.1 km in 12 seconds (330 km/h)',
      otpAttempts: 'Dual-OTP executed within single IP session',
      cctvTimestamp: 'Hostel Gate turnstile recorded courier sitting in common room',
      investigatorNotes: 'Roommate collusion detected; device fingerprints matched requester exactly.',
      confirmedAt: '2026-09-17T18:42:00Z',
      sanction: 'Escrow deposit slashed (25 tokens). Account suspended for 30 academic days.'
    }
  },
  {
    id: 'FRD-2026-042',
    user: 'Aman K. & Priyesh M.',
    regHash: '23BCI**** / 23BCE****',
    title: 'The Xerox Circular Rating Cartel',
    summary: 'Fabricated 18 micro-tasks in 45 minutes to artificially pump runner trust ratings.',
    status: 'CONFIRMED VIOLATION',
    featured: 'month',
    violationType: 'SYBIL_TASK_FARMING',
    microcopy: 'Dignified paper routes require actual paper. Zero xerox sheets printed.',
    evidence: {
      routeDeviation: '0 km traveled — both devices co-located at SJT 4th floor lab',
      otpAttempts: 'Identical sequence tokens submitted back-to-back',
      cctvTimestamp: 'TT Xerox vendor confirmed zero jobs queued or collected',
      investigatorNotes: 'Sybil circular trust-inflation attack ahead of peak semester rush.',
      confirmedAt: '2026-09-02T14:15:00Z',
      sanction: 'Both accounts downgraded to zero trust rating. 150 accumulated bounty tokens revoked.'
    }
  },
  {
    id: 'FRD-2026-021',
    user: 'Deepak T.',
    regHash: '21BME****',
    title: 'The Invisible Lab Coat Transfer',
    summary: 'Claimed lab coat drop-off at SMV while runner GPS pinged Katpadi Railway Station.',
    status: 'CONFIRMED VIOLATION',
    featured: null,
    violationType: 'LOCATION_SPOOFING',
    microcopy: 'Engineering physics requires presence in this dimension.',
    evidence: {
      routeDeviation: 'Runner off campus by 4.2 km during verified delivery window',
      otpAttempts: 'Delivery OTP entered via social engineering phone call',
      cctvTimestamp: 'SMV turnstile confirms student never entered block',
      investigatorNotes: 'Requester coerced over call to disclose OTP early.',
      confirmedAt: '2026-08-25T11:20:00Z',
      sanction: 'Account restricted permanently from runner eligibility.'
    }
  }
];
