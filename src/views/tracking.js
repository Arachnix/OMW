/**
 * Live Tracking & Navigation View
 * OMW Campus GIS Engine — VIT Vellore
 */
import { LeafletCampusMapEngine } from '../map-engine.js';
import { CAMPUS_TURN_BY_TURN_CUES } from '../data/campus-data.js';

export class TrackingView {
  constructor(containerId = 'trackingViewContainer', options = {}) {
    this.container = typeof containerId === 'string' ? document.getElementById(containerId) : containerId;
    this.options = options;
    this.mapEngine = null;
    this.ws = null;
    this.pickupOtp = options.pickupOtp || '4821';
    this.deliveryOtp = options.deliveryOtp || '7392';

    if (this.container) {
      this.render();
      this.initMap();
    }
  }

  render() {
    this.container.innerHTML = `
      <div class="omw-tracking-wrapper" style="max-width: 1080px; margin: 0 auto; padding: 20px;">
        <!-- Top Header & Basemap Controls -->
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; flex-wrap: wrap; gap: 12px;">
          <div>
            <h2 style="margin: 0; font-size: 22px; font-weight: 800; color: #0f172a; display: flex; align-items: center; gap: 8px;">
              <span>🚶‍♂️</span> Live Runner Telemetry
              <span style="font-size: 12px; font-weight: 600; background: #dbeafe; color: #1e40af; padding: 3px 8px; border-radius: 12px;">
                Main Gate ➔ Q Block
              </span>
            </h2>
            <p style="margin: 4px 0 0 0; font-size: 13px; color: #64748b;">
              Road-snapped corridor tracking across 72 GPS waypoints with zero watermarks.
            </p>
          </div>

          <!-- Basemap Switchers -->
          <div style="display: flex; gap: 6px; background: #f1f5f9; padding: 4px; border-radius: 10px;">
            <button class="omw-btn-basemap active" data-basemap="street" style="padding: 6px 12px; border-radius: 8px; border: none; font-size: 12px; font-weight: 600; cursor: pointer; background: #ffffff; color: #0f172a; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
              🗺️ Street
            </button>
            <button class="omw-btn-basemap" data-basemap="satellite" style="padding: 6px 12px; border-radius: 8px; border: none; font-size: 12px; font-weight: 600; cursor: pointer; background: transparent; color: #64748b;">
              🛰️ Satellite
            </button>
            <button class="omw-btn-basemap" data-basemap="night" style="padding: 6px 12px; border-radius: 8px; border: none; font-size: 12px; font-weight: 600; cursor: pointer; background: transparent; color: #64748b;">
              🌙 Night Owl
            </button>
          </div>
        </div>

        <!-- Real-Time Telemetry HUD -->
        <div class="omw-tracking-hud">
          <div class="omw-hud-metric">
            <span class="omw-hud-label">Corridor Progress</span>
            <span class="omw-hud-value" id="hudProgress">35%</span>
            <span class="omw-hud-subtext" id="hudRunner">Rohan Mehta</span>
          </div>
          <div class="omw-hud-metric">
            <span class="omw-hud-label">Distance Covered</span>
            <span class="omw-hud-value" id="hudCovered">378m</span>
            <span class="omw-hud-subtext" id="hudRemaining">702m remaining</span>
          </div>
          <div class="omw-hud-metric">
            <span class="omw-hud-label">Energy Burned</span>
            <span class="omw-hud-value" id="hudCalories">~15 kcal</span>
            <span class="omw-hud-subtext">Est. 42 kcal total</span>
          </div>
          <div class="omw-hud-metric">
            <span class="omw-hud-label">Steps Count</span>
            <span class="omw-hud-value" id="hudSteps">~413</span>
            <span class="omw-hud-subtext">Est. 1,180 total</span>
          </div>
        </div>

        <!-- Interactive Map Container -->
        <div style="position: relative;">
          <div id="campusLeafletMap"></div>

          <!-- Floating Interactive Controls -->
          <div style="position: absolute; bottom: 20px; right: 20px; z-index: 1000; display: flex; gap: 8px;">
            <button id="btnAdvanceRunner" style="background: #2563eb; color: #ffffff; border: none; padding: 10px 18px; border-radius: 10px; font-size: 13px; font-weight: 700; cursor: pointer; box-shadow: 0 4px 12px rgba(37,99,235,0.4); display: flex; align-items: center; gap: 6px;">
              <span>⚡ Advance Runner (+25%)</span>
            </button>
            <button id="btnResetRunner" style="background: rgba(15,23,42,0.85); color: #ffffff; border: none; padding: 10px 14px; border-radius: 10px; font-size: 13px; font-weight: 600; cursor: pointer; backdrop-filter: blur(6px);">
              ↺ Reset
            </button>
          </div>
        </div>

        <!-- Dual Column Grid: Turn-by-Turn Cue Sheet & Zero-Trust Dual OTP Desk -->
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 16px; margin-top: 16px;">
          <!-- 6-Stage Turn-by-Turn Navigation Card -->
          <div class="omw-cue-sheet">
            <div class="omw-cue-header">
              <span>📍 Turn-by-Turn Navigation Guide</span>
              <span id="cueActiveStageBadge" style="font-size: 12px; color: #2563eb; font-weight: 700;">Stage 3 of 6</span>
            </div>
            <div id="cueListContainer">
              ${CAMPUS_TURN_BY_TURN_CUES.map((cue, idx) => `
                <div class="omw-cue-step ${idx === 2 ? 'active' : ''}" id="cueStep-${idx + 1}">
                  <div class="omw-cue-badge">${idx + 1}</div>
                  <div class="omw-cue-info">
                    <div class="omw-cue-title">${cue.title}</div>
                    <div class="omw-cue-instruction">${cue.instruction}</div>
                    <div class="omw-cue-distance">+${cue.distanceMeters}m</div>
                  </div>
                </div>
              `).join('')}
            </div>
          </div>

          <!-- Zero-Trust Dual OTP Verification Desk -->
          <div>
            <div class="omw-otp-desk" style="margin-top: 0;">
              <!-- Step 1: Source Pickup OTP -->
              <div class="omw-otp-card">
                <h4>1. Source Pickup OTP</h4>
                <p style="font-size: 11px; color: #64748b; margin: 0 0 10px 0;">
                  Provide to runner upon item handoff at source:
                </p>
                <div class="omw-otp-display" id="displayPickupOtp">${this.pickupOtp}</div>
                <div style="margin-top: 10px;">
                  <span style="font-size: 11px; color: #0d9488; font-weight: 600;">✓ Verified at TT Xerox</span>
                </div>
              </div>

              <!-- Step 2: Destination Delivery OTP -->
              <div class="omw-otp-card">
                <h4>2. Destination Delivery OTP</h4>
                <p style="font-size: 11px; color: #64748b; margin: 0 0 10px 0;">
                  Requester gives to runner upon physical delivery:
                </p>
                <div class="omw-otp-display" id="displayDeliveryOtp">${this.deliveryOtp}</div>
                <div style="margin-top: 10px;">
                  <span style="font-size: 11px; color: #d97706; font-weight: 600;">⌛ Pending at Q Block</span>
                </div>
              </div>
            </div>

            <!-- Zero-Trust Guarantee Box -->
            <div style="margin-top: 16px; background: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 12px; padding: 14px;">
              <h5 style="margin: 0 0 4px 0; font-size: 12px; font-weight: 700; color: #334155;">🛡️ Zero-Trust Handshake Guarantee</h5>
              <p style="margin: 0; font-size: 11px; color: #64748b; line-height: 1.4;">
                Tokens remain securely locked in escrow until the recipient physically inspects the package and submits the 4-digit Delivery OTP.
              </p>
            </div>
          </div>
        </div>
      </div>
    `;

    this.bindEvents();
  }

  initMap() {
    this.mapEngine = new LeafletCampusMapEngine('campusLeafletMap', {
      initialProgress: 0.35,
      onProgressChange: telemetry => this.updateHUD(telemetry)
    });
  }

  bindEvents() {
    // 1. Basemap switcher clicks
    const basemapBtns = this.container.querySelectorAll('.omw-btn-basemap');
    basemapBtns.forEach(btn => {
      btn.addEventListener('click', e => {
        basemapBtns.forEach(b => {
          b.classList.remove('active');
          b.style.background = 'transparent';
          b.style.color = '#64748b';
          b.style.boxShadow = 'none';
        });

        const target = e.currentTarget;
        target.classList.add('active');
        target.style.background = '#ffffff';
        target.style.color = '#0f172a';
        target.style.boxShadow = '0 1px 3px rgba(0,0,0,0.1)';

        const basemapType = target.getAttribute('data-basemap');
        if (this.mapEngine) {
          this.mapEngine.switchBasemap(basemapType);
        }
      });
    });

    // 2. Advance runner button
    const btnAdvance = this.container.querySelector('#btnAdvanceRunner');
    if (btnAdvance) {
      btnAdvance.addEventListener('click', () => {
        if (this.mapEngine) {
          this.mapEngine.advanceProgress(0.25);
        }
      });
    }

    // 3. Reset runner button
    const btnReset = this.container.querySelector('#btnResetRunner');
    if (btnReset) {
      btnReset.addEventListener('click', () => {
        if (this.mapEngine) {
          this.mapEngine.setProgress(0.0);
        }
      });
    }
  }

  updateHUD(telemetry) {
    const elProg = this.container.querySelector('#hudProgress');
    const elCovered = this.container.querySelector('#hudCovered');
    const elRemaining = this.container.querySelector('#hudRemaining');
    const elCalories = this.container.querySelector('#hudCalories');
    const elSteps = this.container.querySelector('#hudSteps');
    const elBadge = this.container.querySelector('#cueActiveStageBadge');

    if (elProg) elProg.textContent = `${telemetry.progressPercent}%`;
    if (elCovered) elCovered.textContent = `${telemetry.coveredDistanceMeters}m`;
    if (elRemaining) elRemaining.textContent = `${telemetry.remainingDistanceMeters}m remaining`;
    if (elCalories) elCalories.textContent = `~${telemetry.caloriesBurned} kcal`;
    if (elSteps) elSteps.textContent = `~${telemetry.stepsCount}`;
    if (elBadge) elBadge.textContent = `Stage ${telemetry.activeStage} of ${telemetry.totalStages}`;

    // Update active cue step highlight
    for (let i = 1; i <= telemetry.totalStages; i++) {
      const step = this.container.querySelector(`#cueStep-${i}`);
      if (step) {
        if (i === telemetry.activeStage) {
          step.classList.add('active');
        } else {
          step.classList.remove('active');
        }
      }
    }
  }
}
