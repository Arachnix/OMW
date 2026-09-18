/**
 * Supabase Client Configuration & Hybrid Fallback Detector
 * OMW Campus Mobility Engine
 */
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const SUPABASE_URL = process.env.SUPABASE_URL || '';
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || '';

let supabaseInstance = null;
let isConfigured = false;

if (SUPABASE_URL && SUPABASE_KEY && !SUPABASE_URL.includes('your-project')) {
  try {
    supabaseInstance = createClient(SUPABASE_URL, SUPABASE_KEY, {
      auth: {
        persistSession: false,
        autoRefreshToken: false
      }
    });
    isConfigured = true;
    console.log('⚡ [Supabase DB]: Live Supabase Client connected to', SUPABASE_URL);
  } catch (err) {
    console.warn('⚠️ [Supabase DB]: Initialization error, switching to fallback mode:', err.message);
    supabaseInstance = null;
    isConfigured = false;
  }
} else {
  console.log('ℹ️ [Supabase DB]: SUPABASE_URL not configured. Operating in local memory/hybrid fallback mode.');
}

export const supabase = supabaseInstance;
export const isSupabaseLive = () => isConfigured;
export const getSupabaseClient = () => supabaseInstance;
