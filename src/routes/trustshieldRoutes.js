/**
 * TrustShield & "Fraud of the Day / Month" Showcase Endpoints
 */
import { Router } from 'express';
import { store } from '../data/store.js';
import { socketService } from '../services/socket/socketService.js';
import { requireAuth, requireRole } from '../utils/auth.js';

const router = Router();

/**
 * GET /api/trustshield/showcase
 * Public "The New Yorker" style editorial showcase
 */
router.get('/showcase', (req, res) => {
  const showcase = store.getShowcase();

  res.json({
    success: true,
    philosophy: 'Editorial, dignified, and witty deterrence. Zero punitive hostility.',
    showcase: {
      fraudOfDay: showcase.fraudOfDay,
      fraudOfMonth: showcase.fraudOfMonth,
      pastCases: showcase.pastCases
    }
  });
});

/**
 * POST /api/admin/fraud/:id/feature
 * Proctor or Admin features an incident as 'day', 'month', or unfeatures it.
 * Requires a signed-in account with the admin role.
 */
const featurePaths = ['/admin/fraud/:id/feature', '/:id/feature'];

router.post(featurePaths, requireAuth, requireRole('admin'), (req, res) => {
  const { id } = req.params;
  const { featured } = req.body; // 'day' | 'month' | null

  if (featured !== 'day' && featured !== 'month' && featured !== null) {
    return res.status(400).json({
      success: false,
      error: 'featured must be "day", "month", or null'
    });
  }

  const updatedCase = store.setFraudFeatured(id, featured);

  if (!updatedCase) {
    return res.status(404).json({
      success: false,
      error: `Fraud incident with id ${id} not found`
    });
  }

  // Broadcast TrustShield alert if newly featured
  if (featured) {
    socketService.broadcastTrustShieldAlert(updatedCase);
  }

  res.json({
    success: true,
    message: featured 
      ? `Incident featured as Fraud of the ${featured === 'day' ? 'Day' : 'Month'}`
      : 'Incident unfeatured from showcase banner',
    case: updatedCase
  });
});

export default router;
