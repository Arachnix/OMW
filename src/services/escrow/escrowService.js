/**
 * Escrow Service: Atomic Locking, Staking, Payout & Refund Logic
 */
import { store } from '../../data/store.js';

export class EscrowService {
  /**
   * Locks 100% of task wager from requester balance into escrow
   */
  static lockRequesterEscrow(userId, taskId, amount) {
    const wallet = store.getWallet(userId);
    if (wallet.availableTokens < amount) {
      throw new Error(`Insufficient tokens. Available: ${wallet.availableTokens}, Required: ${amount}`);
    }

    wallet.availableTokens -= amount;
    wallet.escrowLocked += amount;

    store.addTransaction({
      userId,
      type: 'ESCROW_LOCK',
      tokens: -amount,
      reference: `Task ${taskId} bounty locked in escrow`,
      referenceTaskId: taskId,
      status: 'COMPLETED'
    });

    return wallet;
  }

  /**
   * Locks commitment deposit (~25%) from runner balance upon task claim
   */
  static lockRunnerStake(runnerId, taskId, stakeAmount) {
    const wallet = store.getWallet(runnerId);
    if (wallet.availableTokens < stakeAmount) {
      throw new Error(`Insufficient tokens for runner stake. Available: ${wallet.availableTokens}, Required: ${stakeAmount}`);
    }

    wallet.availableTokens -= stakeAmount;
    wallet.runnerStaked += stakeAmount;

    store.addTransaction({
      userId: runnerId,
      type: 'RUNNER_STAKE_LOCK',
      tokens: -stakeAmount,
      reference: `Task ${taskId} anti-flaking commitment stake locked`,
      referenceTaskId: taskId,
      status: 'COMPLETED'
    });

    return wallet;
  }

  /**
   * Atomically releases task bounty and runner stake upon Delivery OTP verification
   */
  static releaseEscrowOnDelivery(task) {
    const requesterWallet = store.getWallet(task.requesterId);
    const runnerWallet = store.getWallet(task.runnerId);

    // 1. Release requester escrow
    requesterWallet.escrowLocked = Math.max(0, requesterWallet.escrowLocked - task.wager);

    // 2. Transfer bounty tokens to runner
    runnerWallet.availableTokens += task.wager;

    // 3. Return runner's commitment deposit stake
    runnerWallet.runnerStaked = Math.max(0, runnerWallet.runnerStaked - task.runnerStakeLocked);
    runnerWallet.availableTokens += task.runnerStakeLocked;

    // Record transactions
    store.addTransaction({
      userId: task.requesterId,
      type: 'ESCROW_RELEASE',
      tokens: 0,
      reference: `Task ${task.id} delivery verified; escrow settled`,
      referenceTaskId: task.id,
      status: 'COMPLETED'
    });

    store.addTransaction({
      userId: task.runnerId,
      type: 'BOUNTY_PAYOUT',
      tokens: task.wager,
      reference: `Task ${task.id} bounty payout received`,
      referenceTaskId: task.id,
      status: 'COMPLETED'
    });

    store.addTransaction({
      userId: task.runnerId,
      type: 'STAKE_RETURN',
      tokens: task.runnerStakeLocked,
      reference: `Task ${task.id} runner commitment stake returned`,
      referenceTaskId: task.id,
      status: 'COMPLETED'
    });

    return {
      bountyPaid: task.wager,
      stakeReturned: task.runnerStakeLocked,
      runnerBalance: runnerWallet.availableTokens
    };
  }

  /**
   * Refunds locked escrow to requester if task is cancelled
   */
  static refundEscrowOnCancel(task) {
    const requesterWallet = store.getWallet(task.requesterId);
    requesterWallet.escrowLocked = Math.max(0, requesterWallet.escrowLocked - task.wager);
    requesterWallet.availableTokens += task.wager;

    store.addTransaction({
      userId: task.requesterId,
      type: 'ESCROW_REFUND',
      tokens: task.wager,
      reference: `Task ${task.id} cancelled; escrow refunded`,
      referenceTaskId: task.id,
      status: 'COMPLETED'
    });

    return {
      refundedTokens: task.wager,
      newAvailableBalance: requesterWallet.availableTokens
    };
  }

  /**
   * Cancels a task a runner has already claimed. The requester pays a flat
   * fee to the runner for their travel time; the rest of the escrow is
   * refunded and the runner's stake is returned.
   */
  static settleLateCancel(task, fee) {
    const requesterWallet = store.getWallet(task.requesterId);
    const runnerWallet = store.getWallet(task.runnerId);
    const charged = Math.min(fee, task.wager);

    requesterWallet.escrowLocked = Math.max(0, requesterWallet.escrowLocked - task.wager);
    requesterWallet.availableTokens += task.wager - charged;

    runnerWallet.runnerStaked = Math.max(0, runnerWallet.runnerStaked - task.runnerStakeLocked);
    runnerWallet.availableTokens += task.runnerStakeLocked + charged;

    store.addTransaction({
      userId: task.requesterId,
      type: 'ESCROW_REFUND',
      tokens: task.wager - charged,
      reference: `Task ${task.id} cancelled after acceptance; ${charged} token fee to runner`,
      referenceTaskId: task.id,
      status: 'COMPLETED'
    });

    store.addTransaction({
      userId: task.runnerId,
      type: 'CANCELLATION_FEE',
      tokens: charged,
      reference: `Task ${task.id} cancelled by requester; travel compensation`,
      referenceTaskId: task.id,
      status: 'COMPLETED'
    });

    store.addTransaction({
      userId: task.runnerId,
      type: 'STAKE_RETURN',
      tokens: task.runnerStakeLocked,
      reference: `Task ${task.id} runner commitment stake returned`,
      referenceTaskId: task.id,
      status: 'COMPLETED'
    });

    return {
      refundedTokens: task.wager - charged,
      feeCharged: charged,
      newAvailableBalance: requesterWallet.availableTokens
    };
  }

  /**
   * Slashes runner's stake if task is abandoned or confirmed fraudulent
   */
  static slashRunnerStake(task, reason = 'Task abandoned') {
    const runnerWallet = store.getWallet(task.runnerId);
    const slashedAmount = task.runnerStakeLocked;
    runnerWallet.runnerStaked = Math.max(0, runnerWallet.runnerStaked - slashedAmount);

    store.addTransaction({
      userId: task.runnerId,
      type: 'STAKE_SLASHED',
      tokens: -slashedAmount,
      reference: `Task ${task.id} stake slashed: ${reason}`,
      referenceTaskId: task.id,
      status: 'COMPLETED'
    });

    return {
      slashedAmount,
      runnerBalance: runnerWallet.availableTokens
    };
  }
}
