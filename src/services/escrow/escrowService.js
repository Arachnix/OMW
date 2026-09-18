/**
 * Escrow Service: Atomic Locking, Staking, Slashing & Payout Logic
 * OMW Campus Logistics Engine
 */
import { store } from '../../data/store.js';
import { WalletRepository } from '../../db/repositories/walletRepository.js';
import { isSupabaseLive } from '../../db/supabaseClient.js';
import { calculateSlashingSplit } from '../../utils/tokenomics.js';

export class EscrowService {
  /**
   * Locks 100% of task wager from requester balance into escrow
   */
  static async lockRequesterEscrow(userId, taskId, amount) {
    const wallet = store.getWallet(userId);
    if (wallet.availableTokens < amount) {
      throw new Error(`Insufficient tokens. Available: ${wallet.availableTokens}, Required: ${amount}`);
    }

    wallet.availableTokens -= amount;
    wallet.escrowLocked += amount;

    // Sync with Supabase if live
    if (isSupabaseLive()) {
      await WalletRepository.updateBalances(userId, {
        availableTokens: wallet.availableTokens,
        escrowLocked: wallet.escrowLocked
      });
    }

    const tx = store.addTransaction({
      userId,
      type: 'ESCROW_LOCK',
      tokens: -amount,
      reference: `Task ${taskId} bounty locked in escrow`,
      referenceTaskId: taskId,
      status: 'COMPLETED'
    });

    return {
      wallet,
      transactionId: tx.id,
      lockedAmount: amount
    };
  }

  /**
   * Locks commitment deposit (~25%) from runner balance upon task claim
   */
  static async lockRunnerStake(runnerId, taskId, stakeAmount) {
    const wallet = store.getWallet(runnerId);
    if (wallet.availableTokens < stakeAmount) {
      throw new Error(`Insufficient tokens for runner stake. Available: ${wallet.availableTokens}, Required: ${stakeAmount}`);
    }

    wallet.availableTokens -= stakeAmount;
    wallet.runnerStaked += stakeAmount;

    // Sync with Supabase if live
    if (isSupabaseLive()) {
      await WalletRepository.updateBalances(runnerId, {
        availableTokens: wallet.availableTokens,
        runnerStaked: wallet.runnerStaked
      });
    }

    const tx = store.addTransaction({
      userId: runnerId,
      type: 'RUNNER_STAKE_LOCK',
      tokens: -stakeAmount,
      reference: `Task ${taskId} anti-flaking commitment stake locked`,
      referenceTaskId: taskId,
      status: 'COMPLETED'
    });

    return {
      wallet,
      transactionId: tx.id,
      stakedAmount: stakeAmount
    };
  }

  /**
   * Atomically releases task bounty and runner stake upon Delivery OTP verification
   */
  static async releaseEscrowOnDelivery(task) {
    const requesterWallet = store.getWallet(task.requesterId);
    const runnerWallet = store.getWallet(task.runnerId);

    // 1. Release requester escrow
    requesterWallet.escrowLocked = Math.max(0, requesterWallet.escrowLocked - task.wager);

    // 2. Transfer bounty tokens to runner
    runnerWallet.availableTokens += task.wager;

    // 3. Return runner's commitment deposit stake
    runnerWallet.runnerStaked = Math.max(0, runnerWallet.runnerStaked - task.runnerStakeLocked);
    runnerWallet.availableTokens += task.runnerStakeLocked;

    // Sync with Supabase if live
    if (isSupabaseLive()) {
      await Promise.all([
        WalletRepository.updateBalances(task.requesterId, {
          escrowLocked: requesterWallet.escrowLocked
        }),
        WalletRepository.updateBalances(task.runnerId, {
          availableTokens: runnerWallet.availableTokens,
          runnerStaked: runnerWallet.runnerStaked
        })
      ]);
    }

    // Record immutable audit ledger transactions
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
      runnerBalance: runnerWallet.availableTokens,
      requesterEscrowRemaining: requesterWallet.escrowLocked
    };
  }

  /**
   * Refunds locked escrow to requester if task is cancelled or expired via TTL
   */
  static async refundEscrowOnCancel(task, reason = 'Task cancelled') {
    const requesterWallet = store.getWallet(task.requesterId);
    requesterWallet.escrowLocked = Math.max(0, requesterWallet.escrowLocked - task.wager);
    requesterWallet.availableTokens += task.wager;

    // Sync with Supabase if live
    if (isSupabaseLive()) {
      await WalletRepository.updateBalances(task.requesterId, {
        availableTokens: requesterWallet.availableTokens,
        escrowLocked: requesterWallet.escrowLocked
      });
    }

    store.addTransaction({
      userId: task.requesterId,
      type: 'ESCROW_REFUND',
      tokens: task.wager,
      reference: `Task ${task.id} refunded (${reason})`,
      referenceTaskId: task.id,
      status: 'COMPLETED'
    });

    return {
      refundedTokens: task.wager,
      newAvailableBalance: requesterWallet.availableTokens
    };
  }

  /**
   * Slashes runner's stake if task is abandoned or confirmed fraudulent.
   * Allocation: 50% credited to requester as compensation, 50% burned by platform sink.
   */
  static async slashRunnerStake(task, reason = 'Task abandoned by runner') {
    const runnerWallet = store.getWallet(task.runnerId);
    const requesterWallet = store.getWallet(task.requesterId);
    const slashedAmount = task.runnerStakeLocked;

    if (slashedAmount <= 0) {
      return { slashedAmount: 0 };
    }

    // 1. Deduct stake from runner
    runnerWallet.runnerStaked = Math.max(0, runnerWallet.runnerStaked - slashedAmount);

    // 2. Distribute 50% compensation to requester, 50% burn
    const split = calculateSlashingSplit(slashedAmount);
    requesterWallet.availableTokens += split.requesterCompensation;

    // Sync with Supabase if live
    if (isSupabaseLive()) {
      await Promise.all([
        WalletRepository.updateBalances(task.runnerId, {
          runnerStaked: runnerWallet.runnerStaked
        }),
        WalletRepository.updateBalances(task.requesterId, {
          availableTokens: requesterWallet.availableTokens
        })
      ]);
    }

    // Record immutable audit ledger entries
    store.addTransaction({
      userId: task.runnerId,
      type: 'STAKE_SLASHED',
      tokens: -slashedAmount,
      reference: `Task ${task.id} runner stake slashed: ${reason}`,
      referenceTaskId: task.id,
      status: 'COMPLETED'
    });

    if (split.requesterCompensation > 0) {
      store.addTransaction({
        userId: task.requesterId,
        type: 'ESCROW_REFUND',
        tokens: split.requesterCompensation,
        reference: `Task ${task.id} runner abandonment compensation credited`,
        referenceTaskId: task.id,
        status: 'COMPLETED'
      });
    }

    return {
      slashedAmount,
      requesterCompensation: split.requesterCompensation,
      platformBurn: split.platformBurn,
      runnerBalance: runnerWallet.availableTokens,
      requesterBalance: requesterWallet.availableTokens
    };
  }
}
