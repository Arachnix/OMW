/**
 * WebSocket Service for Real-Time Telemetry, En-Route Alerts & Task State Sync
 */
import { WebSocketServer, WebSocket } from 'ws';
import { CAMPUS_ROAD_WAYPOINTS, CAMPUS_TURN_BY_TURN_CUES } from '../../data/campus-data.js';
import { findClosestWaypoint, calculateHaversineDistance } from '../../utils/geo.js';

class SocketService {
  constructor() {
    this.wss = null;
    this.clients = new Set();
    this.runnerPositions = new Map(); // runnerId -> { lat, lng, progressPercent, lastUpdated }
  }

  init(server) {
    this.wss = new WebSocketServer({ server, path: '/ws' });

    this.wss.on('connection', (ws, req) => {
      this.clients.add(ws);
      ws.isAlive = true;

      ws.on('pong', () => {
        ws.isAlive = true;
      });

      // Send initial connection ACK
      ws.send(JSON.stringify({
        type: 'CONNECTION_ESTABLISHED',
        message: 'Connected to OMW Real-Time Campus Gateway',
        timestamp: new Date().toISOString()
      }));

      ws.on('message', data => {
        try {
          const payload = JSON.parse(data.toString());
          this.handleIncomingMessage(ws, payload);
        } catch (err) {
          console.error('[WS Error] Failed to parse message:', err.message);
        }
      });

      ws.on('close', () => {
        this.clients.delete(ws);
      });

      ws.on('error', err => {
        console.error('[WS Client Error]:', err.message);
        this.clients.delete(ws);
      });
    });

    // Heartbeat ping every 30s
    const interval = setInterval(() => {
      if (!this.wss) return;
      this.wss.clients.forEach(ws => {
        if (!ws.isAlive) return ws.terminate();
        ws.isAlive = false;
        ws.ping();
      });
    }, 30000);

    this.wss.on('close', () => {
      clearInterval(interval);
    });

    console.log('[OMW WebSocket] Server initialized on path /ws');
  }

  handleIncomingMessage(ws, payload) {
    const { type, ...data } = payload;

    switch (type) {
      case 'RUNNER_LOCATION_UPDATE':
        this.handleRunnerLocationUpdate(data);
        break;

      case 'SUBSCRIBE_TASK':
        ws.subscribedTaskId = data.taskId;
        break;

      case 'RUNNER_ARRIVED':
        // Runner is at the drop-off; tell the requester to get their code ready.
        if (data.taskId) {
          this.broadcast({
            type: 'RUNNER_ARRIVED',
            data: {
              taskId: data.taskId,
              runnerId: data.runnerId,
              timestamp: new Date().toISOString()
            }
          });
        }
        break;

      default:
        break;
    }
  }

  handleRunnerLocationUpdate({ runnerId, lat, lng, speedKmh = 4.5 }) {
    if (!runnerId || lat === undefined || lng === undefined) return;

    const waypointInfo = findClosestWaypoint([lat, lng], CAMPUS_ROAD_WAYPOINTS);
    
    // Determine active turn-by-turn cue stage based on progress
    const stageIndex = Math.min(
      CAMPUS_TURN_BY_TURN_CUES.length - 1,
      Math.floor((waypointInfo.progressPercent / 100) * CAMPUS_TURN_BY_TURN_CUES.length)
    );
    const activeCue = CAMPUS_TURN_BY_TURN_CUES[stageIndex];

    const locationState = {
      runnerId,
      coords: [lat, lng],
      speedKmh,
      closestWaypointIndex: waypointInfo.index,
      progressPercent: waypointInfo.progressPercent,
      activeCue,
      lastUpdated: new Date().toISOString()
    };

    this.runnerPositions.set(runnerId, locationState);

    // Broadcast location to all clients
    this.broadcast({
      type: 'RUNNER_LOCATION_BROADCAST',
      data: locationState
    });
  }

  broadcast(messageObj) {
    const serialized = JSON.stringify(messageObj);
    for (const client of this.clients) {
      if (client.readyState === WebSocket.OPEN) {
        client.send(serialized);
      }
    }
  }

  broadcastTaskStateChange(task, actorId) {
    this.broadcast({
      type: 'TASK_STATE_CHANGED',
      data: {
        taskId: task.id,
        status: task.status,
        task,
        actorId,
        timestamp: new Date().toISOString()
      }
    });
  }

  broadcastEnRouteAlert(task) {
    // Check if any runner is within 300m of pickup
    for (const [runnerId, loc] of this.runnerPositions.entries()) {
      const dist = calculateHaversineDistance(loc.coords, task.pickupCoords);
      if (dist <= 300) {
        this.broadcast({
          type: 'EN_ROUTE_TASK_ALERT',
          data: {
            runnerId,
            taskId: task.id,
            title: task.title,
            bounty: task.wager,
            distanceToPickupMeters: dist,
            pickupName: task.pickupNodeName
          }
        });
      }
    }
  }

  broadcastTrustShieldAlert(caseItem) {
    this.broadcast({
      type: 'TRUSTSHIELD_ALERT',
      data: {
        alertType: caseItem.featured === 'day' ? 'FRAUD_OF_THE_DAY' : 'FRAUD_OF_THE_MONTH',
        caseId: caseItem.id,
        user: caseItem.user,
        title: caseItem.title,
        microcopy: caseItem.microcopy,
        featured: caseItem.featured
      }
    });
  }
}

export const socketService = new SocketService();
