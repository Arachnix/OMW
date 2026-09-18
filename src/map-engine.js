/**
 * OMW Leaflet Campus GIS Map Engine (VIT Vellore)
 * Features: Zero-API-Key Multi-Basemap, 72 Road Waypoints, Hover-Only Landmarks & Runner Telemetry
 */
import {
  VIT_LOCATIONS,
  CAMPUS_ROAD_WAYPOINTS,
  CAMPUS_TURN_BY_TURN_CUES
} from './data/campus-data.js';

export class LeafletCampusMapEngine {
  /**
   * @param {string} containerId HTML element ID for Leaflet map container
   * @param {object} options Configuration options
   */
  constructor(containerId = 'campusLeafletMap', options = {}) {
    this.containerId = containerId;
    this.options = {
      initialProgress: options.initialProgress !== undefined ? options.initialProgress : 0.35,
      defaultBasemap: options.defaultBasemap || 'street',
      zoom: options.zoom || 16.5,
      center: options.center || [12.9708, 79.1600], // Central VIT Vellore Boulevard
      onProgressChange: options.onProgressChange || null,
      ...options
    };

    this.map = null;
    this.currentBasemap = this.options.defaultBasemap;
    this.tileLayers = {};
    this.landmarkMarkers = [];
    this.corridorPolyline = null;
    this.runnerMarker = null;
    this.currentProgress = this.options.initialProgress > 1 ? this.options.initialProgress / 100 : this.options.initialProgress;

    // Corridor metrics (Main Gate to Q Block)
    this.totalCorridorDistanceMeters = 1080;
    this.totalCorridorCalories = 42;
    this.totalCorridorSteps = 1180;

    this.init();
  }

  /**
   * Initializes Leaflet Map instance and layers
   */
  init() {
    const L = typeof window !== 'undefined' ? window.L : null;
    if (!L) {
      console.warn('⚠️ [LeafletCampusMapEngine]: Window.L not found. Ensure Leaflet.js script is included in HTML head.');
      return;
    }

    const container = document.getElementById(this.containerId);
    if (!container) {
      console.warn(`⚠️ [LeafletCampusMapEngine]: Container #${this.containerId} not found in DOM.`);
      return;
    }

    // 1. Instantiate Map with VIT Vellore Center
    this.map = L.map(this.containerId, {
      center: this.options.center,
      zoom: this.options.zoom,
      minZoom: 15,
      maxZoom: 19,
      zoomControl: true,
      attributionControl: false // Attribution rendered cleanly in UI
    });

    // 2. Setup Zero-API-Key Basemaps
    // A. OpenStreetMap Standard (100% Free, Zero Watermark)
    this.tileLayers.street = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© OpenStreetMap contributors'
    });

    // B. Esri World Imagery (High-Res Real Orbital Satellite)
    this.tileLayers.satellite = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
      maxZoom: 19,
      attribution: 'Tiles © Esri'
    });

    // Apply default layer
    this.applyBasemap(this.currentBasemap);

    // 3. Render Zero-Clutter Hover-Only Landmark Dots
    this.renderLandmarks();

    // 4. Render 72-Point Road-Snapped Delivery Corridor
    this.renderCorridor();

    // 5. Render Animated Runner Beacon
    this.renderRunner();

    // 6. Set initial position
    this.setProgress(this.currentProgress);
  }

  /**
   * Switches map layer between 'street', 'satellite', and 'night'
   */
  switchBasemap(type) {
    if (!['street', 'satellite', 'night'].includes(type)) return;
    this.currentBasemap = type;
    this.applyBasemap(type);
  }

  applyBasemap(type) {
    if (!this.map) return;
    const container = this.map.getContainer();

    // Remove existing layers
    Object.values(this.tileLayers).forEach(layer => {
      if (this.map.hasLayer(layer)) this.map.removeLayer(layer);
    });

    if (type === 'satellite') {
      container.classList.remove('leaflet-tiles-dark-filter');
      this.tileLayers.satellite.addTo(this.map);
    } else if (type === 'night') {
      container.classList.add('leaflet-tiles-dark-filter');
      this.tileLayers.street.addTo(this.map);
    } else {
      // Standard Street
      container.classList.remove('leaflet-tiles-dark-filter');
      this.tileLayers.street.addTo(this.map);
    }
  }

  /**
   * Renders 24 campus landmark nodes as sleek 13px hover-only dots
   */
  renderLandmarks() {
    const L = typeof window !== 'undefined' ? window.L : null;
    if (!this.map || !L) return;

    // Category emoji mapping
    const categoryIcons = {
      academic: '🎓',
      food: '☕',
      hostel: '🏢',
      facility: '⚙️',
      gate: '🚪'
    };

    VIT_LOCATIONS.forEach(loc => {
      const iconEmoji = categoryIcons[loc.category] || '📍';

      // Custom HTML Marker: 13px dot with hover-only bubble
      const dotHtml = `
        <div class="omw-landmark-node">
          <div class="omw-landmark-dot" style="background-color: ${loc.color};"></div>
          <div class="landmark-hover-bubble">
            <span>${iconEmoji}</span>
            <span>${loc.name}</span>
          </div>
        </div>
      `;

      const customIcon = L.divIcon({
        className: 'omw-landmark-marker-wrap',
        html: dotHtml,
        iconSize: [20, 20],
        iconAnchor: [10, 10]
      });

      const marker = L.marker(loc.coords, { icon: customIcon });
      marker.addTo(this.map);
      this.landmarkMarkers.push(marker);
    });
  }

  /**
   * Draws polyline snapping strictly to the 72 physical road GPS coordinates
   */
  renderCorridor() {
    const L = typeof window !== 'undefined' ? window.L : null;
    if (!this.map || !L) return;

    // Active corridor polyline
    this.corridorPolyline = L.polyline(CAMPUS_ROAD_WAYPOINTS, {
      color: '#2563eb',
      weight: 5,
      opacity: 0.85,
      lineJoin: 'round',
      lineCap: 'round',
      dashArray: null
    }).addTo(this.map);

    // Start Pin: Main Gate Katpadi Canopy
    const startHtml = `<div class="omw-terminus-pin" style="background: #334155;"></div>`;
    L.marker(CAMPUS_ROAD_WAYPOINTS[0], {
      icon: L.divIcon({ html: startHtml, iconSize: [18, 18], iconAnchor: [9, 9] })
    }).addTo(this.map);

    // Terminus Pin: Q Block Men's Residential Tower
    const endHtml = `<div class="omw-terminus-pin" style="background: #0d9488;"></div>`;
    L.marker(CAMPUS_ROAD_WAYPOINTS[CAMPUS_ROAD_WAYPOINTS.length - 1], {
      icon: L.divIcon({ html: endHtml, iconSize: [18, 18], iconAnchor: [9, 9] })
    }).addTo(this.map);
  }

  /**
   * Instantiates animated runner beacon marker
   */
  renderRunner() {
    const L = typeof window !== 'undefined' ? window.L : null;
    if (!this.map || !L) return;

    const runnerHtml = `
      <div class="omw-runner-marker">
        <div class="omw-runner-pulse"></div>
        <div class="omw-runner-avatar">RM</div>
      </div>
    `;

    const runnerIcon = L.divIcon({
      className: 'omw-runner-wrap',
      html: runnerHtml,
      iconSize: [48, 48],
      iconAnchor: [24, 24]
    });

    this.runnerMarker = L.marker(CAMPUS_ROAD_WAYPOINTS[0], {
      icon: runnerIcon,
      zIndexOffset: 1000
    }).addTo(this.map);
  }

  /**
   * Updates progress along the 72 road waypoints (0.0 to 1.0)
   */
  setProgress(progress) {
    this.currentProgress = Math.max(0, Math.min(1, progress));

    const totalWaypoints = CAMPUS_ROAD_WAYPOINTS.length;
    const targetFloatIndex = this.currentProgress * (totalWaypoints - 1);
    const baseIndex = Math.floor(targetFloatIndex);
    const nextIndex = Math.min(totalWaypoints - 1, baseIndex + 1);
    const fraction = targetFloatIndex - baseIndex;

    const currentWp = CAMPUS_ROAD_WAYPOINTS[baseIndex];
    const nextWp = CAMPUS_ROAD_WAYPOINTS[nextIndex];

    // Linear interpolation between consecutive road waypoints
    const interpolatedLat = currentWp[0] + (nextWp[0] - currentWp[0]) * fraction;
    const interpolatedLng = currentWp[1] + (nextWp[1] - currentWp[1]) * fraction;
    const runnerCoord = [interpolatedLat, interpolatedLng];

    if (this.runnerMarker) {
      this.runnerMarker.setLatLng(runnerCoord);
    }

    // Telemetry calculations
    const telemetry = this.getTelemetry();

    if (typeof this.options.onProgressChange === 'function') {
      this.options.onProgressChange(telemetry);
    }

    return telemetry;
  }

  /**
   * Advances runner progress by a specified delta (e.g. +0.25 for +25%)
   */
  advanceProgress(delta = 0.25) {
    let nextProgress = this.currentProgress + delta;
    if (nextProgress > 1.0) nextProgress = 0.0; // Loop around for testing
    return this.setProgress(nextProgress);
  }

  /**
   * Calculates comprehensive live telemetry metrics
   */
  getTelemetry() {
    const progressPercent = Math.round(this.currentProgress * 100);
    const coveredDistance = Math.round(this.totalCorridorDistanceMeters * this.currentProgress);
    const remainingDistance = Math.max(0, this.totalCorridorDistanceMeters - coveredDistance);
    const caloriesBurned = Math.round(this.totalCorridorCalories * this.currentProgress);
    const stepsCount = Math.round(this.totalCorridorSteps * this.currentProgress);

    // Active Turn-by-Turn Cue Calculation
    let activeStage = 1;
    if (this.currentProgress >= 0.85) activeStage = 6;
    else if (this.currentProgress >= 0.65) activeStage = 5;
    else if (this.currentProgress >= 0.45) activeStage = 4;
    else if (this.currentProgress >= 0.30) activeStage = 3;
    else if (this.currentProgress >= 0.15) activeStage = 2;

    const activeCue = CAMPUS_TURN_BY_TURN_CUES[activeStage - 1] || CAMPUS_TURN_BY_TURN_CUES[0];

    return {
      progressPercent,
      progressFraction: this.currentProgress,
      coveredDistanceMeters: coveredDistance,
      remainingDistanceMeters: remainingDistance,
      caloriesBurned,
      stepsCount,
      activeStage,
      activeCue,
      currentRunner: 'Rohan Mehta (22BEE0819)',
      totalStages: CAMPUS_TURN_BY_TURN_CUES.length
    };
  }
}
