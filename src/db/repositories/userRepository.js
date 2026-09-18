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
          email: data.email || null,
          admissionYear: data.admission_year || null,
          academicStanding: data.academic_standing || null,
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

  static async getByEmail(email) {
    if (!email) return null;
    const clean = email.trim().toLowerCase();
    if (isSupabaseLive()) {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('email', clean)
        .single();
      if (data) {
        return {
          id: data.id,
          name: data.name,
          email: data.email,
          admissionYear: data.admission_year,
          academicStanding: data.academic_standing,
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
    return store.findUserByEmail(clean);
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
          email: data.email || null,
          admissionYear: data.admission_year || null,
          academicStanding: data.academic_standing || null,
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

  static async create(userData, initialBonusTokens = 20) {
    if (isSupabaseLive()) {
      const row = {
        id: userData.id,
        reg_number: userData.regNumber,
        reg_hash: userData.regHash,
        name: userData.name,
        email: userData.email || null,
        admission_year: userData.admissionYear || null,
        academic_standing: userData.academicStanding || null,
        hostel_block: userData.hostelBlock,
        trust_score: userData.trustScore || 5.0,
        completed_tasks: userData.completedTasks || 0,
        is_restricted: !!userData.isRestricted,
        restriction_notice: userData.restrictionNotice || null,
        role: userData.role || 'student'
      };

      let { data, error } = await supabase
        .from('profiles')
        .upsert(row)
        .select()
        .single();

      if (error && error.message.includes('column')) {
        // Fallback without new columns until migration 002 is executed in Supabase SQL editor
        const safeRow = { ...row };
        delete safeRow.email;
        delete safeRow.admission_year;
        delete safeRow.academic_standing;
        const fallbackRes = await supabase.from('profiles').upsert(safeRow).select().single();
        if (!fallbackRes.error) error = null;
      }

      if (error) {
        console.error('[UserRepository.create Error]:', error.message);
      } else {
        // Also ensure wallet exists with initial 20 non-cashable airdrop tokens
        const walletPayload = {
          user_id: userData.id,
          available_tokens: initialBonusTokens,
          bonus_tokens: initialBonusTokens,
          cashable_tokens: 0.0,
          escrow_locked: 0.0,
          runner_staked: 0.0
        };
        const { error: wErr } = await supabase.from('wallets').upsert(walletPayload);
        if (wErr && wErr.message.includes('column')) {
          delete walletPayload.bonus_tokens;
          delete walletPayload.cashable_tokens;
          await supabase.from('wallets').upsert(walletPayload);
        }
      }
    }
    return store.createUser(userData, initialBonusTokens);
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
