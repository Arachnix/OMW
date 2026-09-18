/**
 * Task Repository (Supabase + Hybrid Fallback)
 */
import { supabase, isSupabaseLive } from '../supabaseClient.js';
import { store } from '../../data/store.js';

export class TaskRepository {
  static async getById(taskId) {
    if (isSupabaseLive()) {
      const { data, error } = await supabase
        .from('tasks')
        .select('*')
        .eq('id', taskId)
        .single();

      if (data) {
        return {
          id: data.id,
          title: data.title,
          category: data.category,
          requesterId: data.requester_id,
          requesterName: data.requester_name,
          requesterTrustScore: Number(data.requester_trust_score),
          pickupNodeId: data.pickup_node_id,
          pickupNodeName: data.pickup_node_name,
          pickupCoords: data.pickup_coords,
          dropNodeId: data.drop_node_id,
          dropNodeName: data.drop_node_name,
          dropCoords: data.drop_coords,
          wager: Number(data.wager),
          notes: data.notes,
          urgency: data.urgency,
          status: data.status,
          runnerId: data.runner_id,
          runnerName: data.runner_name,
          pickupOtp: data.pickup_otp,
          deliveryOtp: data.delivery_otp,
          runnerStakeLocked: Number(data.runner_stake_locked || 0),
          createdAt: data.created_at,
          claimedAt: data.claimed_at,
          expiresAt: data.expires_at,
          completedAt: data.completed_at,
          surgeActive: data.surge_active
        };
      }
    }
    return store.getTask(taskId);
  }

  static async getAll() {
    if (isSupabaseLive()) {
      const { data } = await supabase
        .from('tasks')
        .select('*')
        .order('created_at', { ascending: false });

      if (data && data.length > 0) {
        return data.map(d => ({
          id: d.id,
          title: d.title,
          category: d.category,
          requesterId: d.requester_id,
          requesterName: d.requester_name,
          requesterTrustScore: Number(d.requester_trust_score),
          pickupNodeId: d.pickup_node_id,
          pickupNodeName: d.pickup_node_name,
          pickupCoords: d.pickup_coords,
          dropNodeId: d.drop_node_id,
          dropNodeName: d.drop_node_name,
          dropCoords: d.drop_coords,
          wager: Number(d.wager),
          notes: d.notes,
          urgency: d.urgency,
          status: d.status,
          runnerId: d.runner_id,
          runnerName: d.runner_name,
          pickupOtp: d.pickup_otp,
          deliveryOtp: d.delivery_otp,
          runnerStakeLocked: Number(d.runner_stake_locked || 0),
          createdAt: d.created_at,
          claimedAt: d.claimed_at,
          expiresAt: d.expires_at,
          completedAt: d.completed_at,
          surgeActive: d.surge_active
        }));
      }
    }
    return store.getAllTasks();
  }

  static async save(task) {
    if (isSupabaseLive()) {
      const payload = {
        id: task.id,
        title: task.title,
        category: task.category,
        requester_id: task.requesterId,
        requester_name: task.requesterName,
        requester_trust_score: task.requesterTrustScore || 5.0,
        pickup_node_id: task.pickupNodeId,
        pickup_node_name: task.pickupNodeName,
        pickup_coords: task.pickupCoords,
        drop_node_id: task.dropNodeId,
        drop_node_name: task.dropNodeName,
        drop_coords: task.dropCoords,
        wager: task.wager,
        notes: task.notes,
        urgency: task.urgency || 'normal',
        status: task.status || 'OPEN',
        runner_id: task.runnerId || null,
        runner_name: task.runnerName || null,
        pickup_otp: task.pickupOtp,
        delivery_otp: task.deliveryOtp,
        runner_stake_locked: task.runnerStakeLocked || 0,
        surge_active: !!task.surgeActive,
        created_at: task.createdAt || new Date().toISOString(),
        claimed_at: task.claimedAt || null,
        expires_at: task.expiresAt || null,
        completed_at: task.completedAt || null
      };

      await supabase.from('tasks').upsert(payload);
    }
    return store.saveTask(task);
  }
}
