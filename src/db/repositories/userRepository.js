/**
 * User / Profile Repository (Supabase + Hybrid Fallback)
 */
import { supabase, isSupabaseLive } from '../supabaseClient.js';
import { store } from '../../data/store.js';

export class UserRepository {
  static async getById(userId) {
    if (isSupabaseLive()) {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();
      if (error && error.code !== 'PGRST116') {
        console.error('[UserRepository.getById Error]:', error.message);
      }
      if (data) {
        return {
          id: data.id,
          name: data.name,
          regNumber: data.reg_number,
          regHash: data.reg_hash,
          hostelBlock: data.hostel_block,
          trustScore: Number(data.trust_score),
          completedTasks: data.completed_tasks,
          isRestricted: data.is_restricted,
          restrictionNotice: data.restriction_notice,
          role: data.role
        };
      }
    }
    // Hybrid fallback
    return store.getUser(userId);
  }

  static async getByRegNumber(regNumber) {
    const clean = regNumber.trim().toUpperCase();
    if (isSupabaseLive()) {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('reg_number', clean)
        .single();
      if (data) {
        return {
          id: data.id,
          name: data.name,
          regNumber: data.reg_number,
          regHash: data.reg_hash,
          hostelBlock: data.hostel_block,
          trustScore: Number(data.trust_score),
          completedTasks: data.completed_tasks,
          isRestricted: data.is_restricted,
          restrictionNotice: data.restriction_notice,
          role: data.role
        };
      }
    }
    return store.findUserByReg(clean);
  }

  static async create(userData) {
    if (isSupabaseLive()) {
      const row = {
        id: userData.id,
        reg_number: userData.regNumber,
        reg_hash: userData.regHash,
        name: userData.name,
        hostel_block: userData.hostelBlock,
        trust_score: userData.trustScore || 5.0,
        completed_tasks: userData.completedTasks || 0,
        is_restricted: !!userData.isRestricted,
        restriction_notice: userData.restrictionNotice || null,
        role: userData.role || 'student'
      };

      const { data, error } = await supabase
        .from('profiles')
        .upsert(row)
        .select()
        .single();

      if (error) {
        console.error('[UserRepository.create Error]:', error.message);
      } else {
        // Also ensure wallet exists
        await supabase
          .from('wallets')
          .upsert({
            user_id: userData.id,
            available_tokens: 50.0,
            escrow_locked: 0.0,
            runner_staked: 0.0
          });
      }
    }
    return store.createUser(userData);
  }

  static async updateTrustScore(userId, trustScore) {
    if (isSupabaseLive()) {
      await supabase
        .from('profiles')
        .update({ trust_score: trustScore })
        .eq('id', userId);
    }
    const user = store.getUser(userId);
    if (user) user.trustScore = trustScore;
    return user;
  }
}
