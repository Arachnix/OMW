# OMW — "ON MY WAY" 🚶‍♂️📦
### Hyper-Local Peer-to-Peer Campus Favor & Logistics Marketplace
**Target Campus:** Vellore Institute of Technology (VIT Vellore Main Campus)  
**Remote Repository:** [https://github.com/codebreaker77/OMW.git](https://github.com/codebreaker77/OMW.git)

---

## 📌 1. Project Overview

**ON MY WAY (OMW)** is a cross-platform, hyper-local peer-to-peer campus mobility and logistics marketplace. Students wager in-app tokens to request micro-favors (fetching food parcels, printouts from Xerox centers, lab coats, hostel deliveries), while other students who are already walking along those routes fulfill them for rewards.

The platform is designed around three foundational pillars:
1. **Real-Time Spatial Matching Engine:** Node-based campus route graph and dynamic ranking that surfaces tasks along walking vectors.
2. **Deflationary Token Economy:** Anti-farming escrow staking, dynamic algorithmic pricing, and pegging via the Razorpay Test Network and campus vendor vouchers.
3. **Zero-Trust Verification & Gamified Deterrence:** Dual-OTP verification handshakes and the *"Fraud of the Day / Month"* human-in-the-loop trust system.

---

## 🏛️ 2. Project Architecture & Directory Structure

```
OMW/
├── .gitignore                      # Ignore node_modules, .env, secrets, CSVs, and temp files
├── README.md                       # Master engineering and architectural documentation
│
├── assets/                         # Static design assets & static datasets
│   ├── data/                       # Campus geography, waypoints, initial fraud telemetry
│   ├── icons/                      # Category icons & SVG markers
│   ├── maps/                       # Local map caches & GeoJSON campus boundaries
│   └── styles/                     # Tailwind tokens, Leaflet dark filters & editorial CSS
│
├── src/
│   ├── components/                 # Reusable UI component library
│   │   ├── common/                 # Modals, buttons, navbar, status badges, toast alerts
│   │   ├── map/                    # Leaflet map container, hover-only markers, route line
│   │   ├── tasks/                  # Smart slider wager calculator, task cards, surge alerts
│   │   ├── trust/                  # Fraud of the Day banner, month showcase, dossier modal
│   │   └── wallet/                 # Token balances, escrow stake cards, Razorpay modal
│   │
│   ├── views/                      # Application route screens
│   │   ├── landing/                # Public splash & product value proposition
│   │   ├── marketplace/            # Dynamic task feed ranked by proximity & bounty
│   │   ├── tracking/               # Live runner navigation HUD, 72-waypoint road tracker
│   │   ├── trust/                  # TrustShield showcase & community deterrence board
│   │   ├── fraud-detail/           # Forensic Case Dossier modal with telemetry breakdown
│   │   ├── profile/                # Student profile, trust rating & account status
│   │   └── admin/                  # Operations desk for human proctors to review & feature fraud
│   │
│   ├── services/                   # Business logic & external communication
│   │   ├── escrow/                 # Requester escrow lock, runner stake, slashing & release
│   │   ├── map/                    # Leaflet engine coordinator, tile manager, route solver
│   │   ├── payment/                # Razorpay Test Network gateway integration
│   │   ├── socket/                 # Real-time WebSocket connection for runner telemetry
│   │   └── trustshield/            # Anomaly scoring (velocity, rapid OTPs, device fingerprint)
│   │
│   └── utils/                      # Helper algorithms & math formulas
│       ├── crypto/                 # Registration number hashing, OTP generator
│       ├── geo/                    # Haversine distance, waypoint interpolation, bearings
│       └── tokenomics/             # Dynamic baseline pricing formula, surge multipliers
│
├── docs/                           # Technical documentation & guides
│   ├── api/                        # API & WebSocket payload contracts
│   ├── architecture/               # System diagrams & state machines
│   └── specifications/             # Full requirements & economics whitepapers
│
├── public/                         # Static public assets (favicons, manifest.json)
└── tests/                          # Test suites
    ├── unit/                       # Formula, escrow, and geospatial unit tests
    └── integration/                # End-to-end task lifecycle and payment flow tests
```

---

## ⚡ 3. Core Engine Specifications

### 3.1 Node-Based Route Matching & "En-Route" Push Alerts
- **Campus Graph Nodes:** 24 high-density locations across VIT Vellore (SJT, TT Xerox, Foody Street, Gazebo, Main Gate, P Block, Q Block, etc.).
- **Real-Time Dynamic Feed Ranking:** Eliminates naive chronological feeds. Instead, tasks are ranked using:
  $$\text{Task Priority} = \frac{\text{Bounty} \times \text{Requester Trust Score}}{\text{Distance to Pickup} + 0.1 \times \text{Detour Distance}} \times \cos(\theta)$$
  Where $\theta$ is the angular offset between the runner’s walking vector and the pickup node.
- **WebSocket "En-Route" Push:** Pushes instant notifications to active walkers when a newly posted favor intersects their corridor.

### 3.2 Dynamic Baseline Pricing Calculator (The Smart Slider)
Ensures equitable compensation for student micro-labor:
$$\text{Wager} = \left[ \text{Base} + (\text{Distance} \times 2) + (\text{Queue Time} \times 0.5) \right] \times \text{Urgency} \times \text{Friction}$$
- **Base:** Campus floor wager (e.g. 10 tokens).
- **Distance:** Snapped road distance between nodes.
- **Queue Time:** Estimated wait at peak spots (TT Xerox, gate delivery queues).
- **Friction Multiplier:** Night delivery / weather conditions ($1.25\times - 1.5\times$).

### 3.3 Zero-Trust Verification & Escrow Staking
- **Requester Escrow:** 100% of task tokens locked upon publishing.
- **Runner Staking:** Agent locks a commitment deposit ($\approx 25\%$) upon claiming to eliminate ghost claims and flaking.
- **Dual-OTP Handshake:**
  - **Pickup OTP:** Provided at source to verify package custody.
  - **Delivery OTP:** Provided by the requester at destination to trigger atomic release of bounty + deposit.
  - **Contactless Fallback:** Geo-tagged and timestamped drop-off photograph verification.

### 3.4 Liquidity & Edge-Case Management
- **30-Minute Time-to-Live (TTL):** Unclaimed tasks auto-expire after 30 minutes; escrowed tokens automatically refund to requester.
- **10-Minute Auto-Surge Prompts:** If a task sits unclaimed for 10 minutes, the requester receives a push: *"Low visibility. Tap to surge +5 tokens to boost acceptance."*

---

## 🛡️ 4. Feature 1: "Fraud of the Day / Month" Trust System

### 4.1 Philosophy & "The New Yorker" Style Deterrence
To curb collusion, artificial rating farming between roommates, and spoofed deliveries, OMW uses an editorial, dignified, and witty deterrence column:
- Clean display serif typography, neutral palettes, and restrained satire (*"OMW remembers. Not the route we recommended"*).
- Eliminates punitive hostility while highlighting factual evidence dossiers.

### 4.2 The 4-Stage Human-in-the-Loop Pipeline
1. **Stage 1 (Detect - TrustShield AI):** Monitors telemetry anomalies (dual-OTP validated in $<15\ \text{s}$, velocity $>20\ \text{km/h}$, matching hardware fingerprints).
2. **Stage 2 (Review - Telemetry Dossier):** Compiles gate CCTV timestamps, GPS road deviation, and counterparty chat records.
3. **Stage 3 (Confirm - Human Proctor):** **Strict rule:** No account is ever sanctioned purely by an automated score. Authorized student proctors verify evidence and mark `CONFIRMED VIOLATION`.
4. **Stage 4 (Feature - Public Showcase):** The case is featured as *"Fraud of the Day"* or *"Fraud of the Month"* on the marketplace feed as an educational trust beacon.

---

## 🗺️ 5. Feature 2: Real-World Campus GIS Map Engine

### 5.1 Zero-API-Key Architecture & Watermark Elimination
Eliminates paid API watermarks by leveraging open GIS layers:
- **Street Basemap:** OpenStreetMap Standard (`https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png`) — free, zero watermarks.
- **Orbital Satellite:** Esri World Imagery (`https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}`) — real satellite photos of VIT rooftops, trees, and quads.
- **Night Owl Mode:** Inverted luminosity CSS filter (`.leaflet-tiles-dark-filter`) for night operations.
- **Custom Key Hook:** Optional modal to attach Mapbox or Google Maps keys saved in `localStorage`.

### 5.2 Clean Hover-Only Landmark Nodes
- **Default State:** Sleek 13px color-coded circular dots (Academic = Blue, Food = Amber, Hostel = Teal, Facility = Slate, Gate = Charcoal).
- **Hover State:** Smooth popup badge displaying name and category emoji directly above the node.
- **Zero Box Clutter:** Bounding boxes, red dashed perimeters, and bulky legends are removed for clarity.

### 5.3 72-Point Road-Snapped Delivery Corridor
The delivery route follows 72 physical GPS waypoints along paved campus roads:
`Main Gate Katpadi Canopy` $\rightarrow$ `Periyar Central Library Avenue` $\rightarrow$ `Anna Auditorium Hexagon` $\rightarrow$ `Central Campus Boulevard (MB/SMV)` $\rightarrow$ `TT Xerox Portico` $\rightarrow$ `Gazebo / Foody Street Walkway` $\rightarrow$ `Health Centre / P Block Road` $\rightarrow$ `Q Block Men's Residential Entrance`.

---

## 💳 6. Razorpay Test Network Integration

OMW uses the **Razorpay Test Network** for fiat token pack purchases and runner earnings redemption.

### 6.1 Environment Configuration
Create a `.env` file in the root directory (do **NOT** commit this file):

```env
# Razorpay Test Credentials (Test Mode Only)
RAZORPAY_KEY_ID=rzp_test_your_key_id_here
RAZORPAY_KEY_SECRET=your_test_key_secret_here

# Network & Environment
OMW_ENV=development
TOKEN_EXCHANGE_RATE=10 # 1 Token = ₹10 INR
PORT=3033
```

### 6.2 Token Value Pegging
- **Fiat Cash-In:** Students purchase token packs (e.g. 50 tokens = ₹500) via Razorpay Checkout in test mode.
- **Fiat Cash-Out:** Verified runners can withdraw surplus tokens to their bank account/UPI.
- **Closed-Loop Campus Perks:** Tokens can also be redeemed for cafeteria vouchers (Gazebo, Foody Street) or campus store merchandise.

---

## 🚀 7. Getting Started

### 7.1 Clone & Setup
```bash
git clone https://github.com/codebreaker77/OMW.git
cd OMW
```

### 7.2 Git Tracking
All component directories contain a `.gitkeep` file ensuring the full architectural tree is tracked and ready for GitHub synchronization.

---
*OMW — On My Way © 2026. Built for high-density campus mobility & zero-trust logistics.*
