/**
 * Map & Locations Repository (Supabase + Hybrid Fallback)
 */
import { supabase, isSupabaseLive } from '../supabaseClient.js';
import { store } from '../../data/store.js';

export class MapRepository {
  static async getAllLocations() {
    if (isSupabaseLive()) {
      const { data } = await supabase
        .from('locations')
        .select('*');

      if (data && data.length > 0) {
        return data.map(loc => ({
          id: loc.id,
          name: loc.name,
          category: loc.category,
          coords: loc.coords,
          description: loc.description,
          popularFor: loc.popular_for,
          activeWagersCount: loc.active_wagers_count || 0
        }));
      }
    }
    return store.locations;
  }

  static async getLocationById(id) {
    if (isSupabaseLive()) {
      const { data } = await supabase
        .from('locations')
        .select('*')
        .eq('id', id)
        .single();

      if (data) {
        return {
          id: data.id,
          name: data.name,
          category: data.category,
          coords: data.coords,
          description: data.description,
          popularFor: data.popular_for,
          activeWagersCount: data.active_wagers_count || 0
        };
      }
    }
    return store.getLocationById(id);
  }
}
