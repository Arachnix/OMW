/**
 * Fraud Showcase Repository (Supabase + Hybrid Fallback)
 */
import { supabase, isSupabaseLive } from '../supabaseClient.js';
import { store } from '../../data/store.js';

export class FraudRepository {
  static async getShowcase() {
    if (isSupabaseLive()) {
      const { data } = await supabase
        .from('fraud_cases')
        .select('*');

      if (data && data.length > 0) {
        const mapped = data.map(c => ({
          id: c.id,
          user: c.user_name || c.user,
          regHash: c.reg_hash || c.regHash,
          title: c.title,
          status: c.status,
          featured: c.featured,
          microcopy: c.microcopy,
          penalty: c.penalty,
          evidence: c.trust_shield_evidence || c.evidence,
          trustShieldEvidence: c.trust_shield_evidence || c.evidence,
          createdAt: c.created_at
        }));

        const fraudOfDay = mapped.find(c => c.featured === 'day') || null;
        const fraudOfMonth = mapped.find(c => c.featured === 'month') || null;
        const pastCases = mapped.filter(c => c.featured !== 'day' && c.featured !== 'month');

        return {
          fraudOfDay,
          fraudOfMonth,
          pastCases,
          allCases: mapped
        };
      }
    }
    return store.getShowcase();
  }

  static async getById(id) {
    if (isSupabaseLive()) {
      const { data } = await supabase
        .from('fraud_cases')
        .select('*')
        .eq('id', id)
        .single();

      if (data) {
        return {
          id: data.id,
          user: data.user_name || data.user,
          regHash: data.reg_hash || data.regHash,
          title: data.title,
          status: data.status,
          featured: data.featured,
          microcopy: data.microcopy,
          penalty: data.penalty,
          evidence: data.trust_shield_evidence || data.evidence,
          trustShieldEvidence: data.trust_shield_evidence || data.evidence,
          createdAt: data.created_at
        };
      }
    }
    return store.getFraudCase(id);
  }

  static async setFeatured(id, featuredType) {
    if (isSupabaseLive()) {
      if (featuredType === 'day' || featuredType === 'month') {
        await supabase
          .from('fraud_cases')
          .update({ featured: null })
          .eq('featured', featuredType);
      }

      await supabase
        .from('fraud_cases')
        .update({ featured: featuredType })
        .eq('id', id);
    }
    return store.setFraudFeatured(id, featuredType);
  }
}
