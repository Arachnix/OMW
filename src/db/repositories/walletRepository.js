/**
 * Wallet & Transaction Repository (Supabase + Hybrid Fallback)
 */
import { supabase, isSupabaseLive } from '../supabaseClient.js';
import { store } from '../../data/store.js';

export class WalletRepository {
  static async getByUserId(userId) {
    if (isSupabaseLive()) {
      const { data, error } = await supabase
        .from('wallets')
        .select('*')
        .eq('user_id', userId)
        .single();

      if (data) {
        return {
          userId: data.user_id,
          availableTokens: Number(data.available_tokens),
          bonusTokens: Number(data.bonus_tokens !== undefined ? data.bonus_tokens : 0),
          cashableTokens: Number(data.cashable_tokens !== undefined ? data.cashable_tokens : data.available_tokens),
          escrowLocked: Number(data.escrow_locked),
          runnerStaked: Number(data.runner_staked)
        };
      }
    }
    return store.getWallet(userId);
  }

  static async updateBalances(userId, { availableTokens, bonusTokens, cashableTokens, escrowLocked, runnerStaked }) {
    if (isSupabaseLive()) {
      const updatePayload = { updated_at: new Date().toISOString() };
      if (availableTokens !== undefined) updatePayload.available_tokens = availableTokens;
      if (bonusTokens !== undefined) updatePayload.bonus_tokens = bonusTokens;
      if (cashableTokens !== undefined) updatePayload.cashable_tokens = cashableTokens;
      if (escrowLocked !== undefined) updatePayload.escrow_locked = escrowLocked;
      if (runnerStaked !== undefined) updatePayload.runner_staked = runnerStaked;

      const { error } = await supabase
        .from('wallets')
        .update(updatePayload)
        .eq('user_id', userId);

      if (error && error.message.includes('column')) {
        const safePayload = { ...updatePayload };
        delete safePayload.bonus_tokens;
        delete safePayload.cashable_tokens;
        await supabase.from('wallets').update(safePayload).eq('user_id', userId);
      }
    }
    const wallet = store.getWallet(userId);
    if (availableTokens !== undefined) wallet.availableTokens = availableTokens;
    if (bonusTokens !== undefined) wallet.bonusTokens = bonusTokens;
    if (cashableTokens !== undefined) wallet.cashableTokens = cashableTokens;
    if (escrowLocked !== undefined) wallet.escrowLocked = escrowLocked;
    if (runnerStaked !== undefined) wallet.runnerStaked = runnerStaked;
    return wallet;
  }

  static async addTransaction(tx) {
    const record = {
      id: tx.id || `tx-${Date.now()}-${Math.random().toString(36).substr(2, 5)}`,
      userId: tx.userId,
      type: tx.type,
      tokens: tx.tokens,
      amountInr: tx.amountInr || 0,
      reference: tx.reference || '',
      referenceTaskId: tx.referenceTaskId || null,
      status: tx.status || 'COMPLETED',
      timestamp: tx.timestamp || new Date().toISOString()
    };

    if (isSupabaseLive()) {
      await supabase
        .from('transactions')
        .insert({
          id: record.id,
          user_id: record.userId,
          type: record.type,
          tokens: record.tokens,
          amount_inr: record.amountInr,
          reference: record.reference,
          reference_task_id: record.referenceTaskId,
          status: record.status,
          created_at: record.timestamp
        });
    }

    return store.addTransaction(record);
  }

  static async getTransactions(userId, limit = 50) {
    if (isSupabaseLive()) {
      let query = supabase
        .from('transactions')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(limit);

      if (userId) {
        query = query.eq('user_id', userId);
      }

      const { data } = await query;
      if (data && data.length > 0) {
        return data.map(tx => ({
          id: tx.id,
          userId: tx.user_id,
          type: tx.type,
          tokens: Number(tx.tokens),
          amountInr: Number(tx.amount_inr),
          reference: tx.reference,
          referenceTaskId: tx.reference_task_id,
          status: tx.status,
          timestamp: tx.created_at
        }));
      }
    }
    return store.getTransactions(userId, limit);
  }
}
