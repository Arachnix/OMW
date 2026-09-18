/**
 * Background Liquidity Daemon: TTL Auto-Expiry, Stale Task Surging & Abandonment Watchdog
 * OMW Campus Logistics Engine
 */
import { store } from '../../data/store.js';
import { EscrowService } from './escrowService.js';
import { socketService } from '../socket/socketService.js';
import {
  TASK_TTL_MINUTES,
  STALE_SURGE_THRESHOLD_MINUTES,
  STALE_SURGE_INCREMENT,
  PICKUP_TIMEOUT_MINUTES
} from '../../utils/tokenomics.js';

class LiquidityDaemon {
  constructor() {
    this.timer = null;
    this.isRunning = false;
    this.intervalMs = 30000; // Run checks every 30 seconds
  }

  /**
   * Starts the background monitoring loop
   */
  start(customIntervalMs) {
    if (this.isRunning) return;
    if (customIntervalMs) this.intervalMs = customIntervalMs;

    this.isRunning = true;
    console.log(`⏱️ [Liquidity Daemon]: Started background monitor (Interval: ${this.intervalMs / 1000}s)`);

    this.timer = setInterval(() => {
      this.runCycle().catch(err => {
        console.error('❌ [Liquidity Daemon Error]:', err.message);
      });
    }, this.intervalMs);
  }

  /**
   * Stops the background monitor
   */
  stop() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
    this.isRunning = false;
    console.log('🛑 [Liquidity Daemon]: Stopped background monitor');
  }

  /**
   * Executes a single evaluation cycle across all active marketplace tasks
   */
  async runCycle() {
    const tasks = store.getAllTasks();
    const now = Date.now();

    const staleSurged = await this.evaluateStaleSurges(tasks, now);
    const ttlExpired = await this.evaluateTTLExpirations(tasks, now);
    const abandonedSlashed = await this.evaluateAbandonedTasks(tasks, now);

    return {
      staleSurged,
      ttlExpired,
      abandonedSlashed,
      evaluatedAt: new Date(now).toISOString()
    };
  }

  /**
   * 1. 10-Minute Stale Task Monitor:
   * Pushes auto-surge notification if a task has zero runner acceptance after 10 mins.
   */
  async evaluateStaleSurges(tasks, now) {
    const staleThresholdMs = STALE_SURGE_THRESHOLD_MINUTES * 60 * 1000;
    const notifiedTaskIds = [];

    for (const task of tasks) {
      if (task.status === 'OPEN' && !task.surgeNotified) {
        const ageMs = now - new Date(task.createdAt).getTime();
        if (ageMs >= staleThresholdMs) {
          task.surgeNotified = true;
          store.saveTask(task);

          // Broadcast alert via WebSocket
          socketService.broadcastToUser(task.requesterId, {
            type: 'STALE_TASK_SURGE_PROMPT',
            data: {
              taskId: task.id,
              title: task.title,
              ageMinutes: Math.floor(ageMs / 60000),
              suggestedSurge: STALE_SURGE_INCREMENT,
              message: `Your task is getting low visibility. Tap to surge by +${STALE_SURGE_INCREMENT} tokens to get it accepted faster.`
            }
          });

          notifiedTaskIds.push(task.id);
          console.log(`📢 [Liquidity Daemon]: Stale surge prompt fired for task ${task.id} (Age: ${Math.floor(ageMs / 60000)}m)`);
        }
      }
    }

    return notifiedTaskIds;
  }

  /**
   * 2. 30-Minute Time-To-Live (TTL) Auto-Refund:
   * Auto-expires unaccepted tasks and 100% refunds escrowed tokens to requester wallet.
   */
  async evaluateTTLExpirations(tasks, now) {
    const ttlThresholdMs = TASK_TTL_MINUTES * 60 * 1000;
    const expiredTaskIds = [];

    for (const task of tasks) {
      if (task.status === 'OPEN') {
        const ageMs = now - new Date(task.createdAt).getTime();
        if (ageMs >= ttlThresholdMs) {
          task.status = 'EXPIRED';
          task.expiredAt = new Date(now).toISOString();

          // Execute 100% escrow refund
          await EscrowService.refundEscrowOnCancel(task, '30-minute TTL expired without runner acceptance');

          store.saveTask(task);

          // Push WebSocket notification
          socketService.broadcastTaskStateChange(task, task.requesterId);
          socketService.broadcastToUser(task.requesterId, {
            type: 'TASK_EXPIRED_REFUNDED',
            data: {
              taskId: task.id,
              title: task.title,
              refundedTokens: task.wager,
              message: `Task ${task.id} expired after 30 minutes. Full escrow of ${task.wager} tokens has been refunded to your wallet.`
            }
          });

          expiredTaskIds.push(task.id);
          console.log(`⌛ [Liquidity Daemon]: Task ${task.id} expired via TTL. Refunded ${task.wager} tokens to ${task.requesterId}`);
        }
      }
    }

    return expiredTaskIds;
  }

  /**
   * 3. 15-Minute Runner In-Flight Abandonment Watchdog:
   * Slashes runner commitment deposit if runner fails to verify pickup within 15 minutes of claiming.
   */
  async evaluateAbandonedTasks(tasks, now) {
    const abandonmentThresholdMs = PICKUP_TIMEOUT_MINUTES * 60 * 1000;
    const slashedTaskIds = [];

    for (const task of tasks) {
      if (task.status === 'CLAIMED' && task.claimedAt) {
        const inFlightMs = now - new Date(task.claimedAt).getTime();
        if (inFlightMs >= abandonmentThresholdMs) {
          const runnerId = task.runnerId;
          console.warn(`⚠️ [Liquidity Daemon]: Runner ${runnerId} abandoned task ${task.id} (In-flight: ${Math.floor(inFlightMs / 60000)}m)`);

          // Slash runner commitment stake
          await EscrowService.slashRunnerStake(task, 'Pickup timeout (15 mins) exceeded without arriving at source');

          // Re-open task to marketplace with priority boost
          task.status = 'OPEN';
          task.runnerId = null;
          task.runnerName = null;
          task.runnerStakeLocked = 0;
          task.claimedAt = null;
          task.reopenedAt = new Date(now).toISOString();
          task.wager += 2; // Compensatory priority boost

          store.saveTask(task);

          // Notify community & requester
          socketService.broadcastTaskStateChange(task, task.requesterId);

          slashedTaskIds.push({
            taskId: task.id,
            slashedRunnerId: runnerId
          });
        }
      }
    }

    return slashedTaskIds;
  }
}

export const liquidityDaemon = new LiquidityDaemon();
