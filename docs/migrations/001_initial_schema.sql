-- ====================================================================
-- OMW — "ON MY WAY" Master Database Schema (Supabase / PostgreSQL)
-- Target Campus: Vellore Institute of Technology (VIT Vellore)
-- ====================================================================

-- 1. Enable UUID Extension if not already active
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. PROFILES (Students, Runners, Campus Proctors)
CREATE TABLE IF NOT EXISTS public.profiles (
    id TEXT PRIMARY KEY,
    reg_number TEXT UNIQUE NOT NULL,
    reg_hash TEXT NOT NULL,
    name TEXT NOT NULL,
    phone TEXT,
    hostel_block TEXT,
    trust_score NUMERIC(3, 2) DEFAULT 5.00 CHECK (trust_score >= 0.0 AND trust_score <= 5.0),
    completed_tasks INTEGER DEFAULT 0,
    is_restricted BOOLEAN DEFAULT FALSE,
    restriction_notice TEXT,
    role TEXT DEFAULT 'student' CHECK (role IN ('student', 'runner', 'admin')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. WALLETS (Token Balances, Escrow Staking)
CREATE TABLE IF NOT EXISTS public.wallets (
    user_id TEXT PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    available_tokens NUMERIC(12, 2) DEFAULT 50.00 CHECK (available_tokens >= 0),
    escrow_locked NUMERIC(12, 2) DEFAULT 0.00 CHECK (escrow_locked >= 0),
    runner_staked NUMERIC(12, 2) DEFAULT 0.00 CHECK (runner_staked >= 0),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TRANSACTIONS (Financial Audit Trail)
CREATE TABLE IF NOT EXISTS public.transactions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN (
        'TOKEN_PURCHASE',
        'ESCROW_LOCK',
        'RUNNER_STAKE_LOCK',
        'ESCROW_RELEASE',
        'BOUNTY_PAYOUT',
        'STAKE_RETURN',
        'ESCROW_REFUND',
        'STAKE_SLASHED',
        'FIAT_WITHDRAWAL',
        'VOUCHER_REDEMPTION'
    )),
    tokens NUMERIC(12, 2) NOT NULL,
    amount_inr NUMERIC(12, 2) DEFAULT 0.00,
    reference TEXT,
    reference_task_id TEXT,
    status TEXT DEFAULT 'COMPLETED' CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. LOCATIONS (VIT Vellore 24 Landmark Nodes)
CREATE TABLE IF NOT EXISTS public.locations (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('academic', 'food', 'hostel', 'facility', 'gate')),
    coords JSONB NOT NULL,
    description TEXT,
    popular_for TEXT,
    active_wagers_count INTEGER DEFAULT 0
);

-- 6. TASKS (Micro-Favor Lifecycle)
CREATE TABLE IF NOT EXISTS public.tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('food', 'facility', 'parcel', 'favor')),
    requester_id TEXT NOT NULL REFERENCES public.profiles(id),
    requester_name TEXT,
    requester_trust_score NUMERIC(3, 2) DEFAULT 5.00,
    pickup_node_id TEXT REFERENCES public.locations(id),
    pickup_node_name TEXT,
    pickup_coords JSONB,
    drop_node_id TEXT REFERENCES public.locations(id),
    drop_node_name TEXT,
    drop_coords JSONB,
    wager NUMERIC(10, 2) NOT NULL CHECK (wager > 0),
    notes TEXT,
    urgency TEXT DEFAULT 'normal' CHECK (urgency IN ('normal', 'urgent', 'critical')),
    status TEXT DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLAIMED', 'PICKED_UP', 'COMPLETED', 'CANCELLED', 'EXPIRED')),
    runner_id TEXT REFERENCES public.profiles(id),
    runner_name TEXT,
    pickup_otp TEXT,
    delivery_otp TEXT,
    runner_stake_locked NUMERIC(10, 2) DEFAULT 0.00,
    surge_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    claimed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

-- 7. FRAUD CASES (TrustShield Telemetry & Editorial Showcase)
CREATE TABLE IF NOT EXISTS public.fraud_cases (
    id TEXT PRIMARY KEY,
    user_id TEXT REFERENCES public.profiles(id),
    user_name TEXT,
    reg_hash TEXT,
    title TEXT NOT NULL,
    status TEXT DEFAULT 'CONFIRMED VIOLATION' CHECK (status IN ('UNDER_REVIEW', 'CONFIRMED VIOLATION', 'DISMISSED')),
    featured TEXT CHECK (featured IN ('day', 'month', NULL)),
    microcopy TEXT,
    penalty JSONB,
    trust_shield_evidence JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. RUNNER TELEMETRY (Live GPS Track Points & Auditing)
CREATE TABLE IF NOT EXISTS public.runner_telemetry (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    runner_id TEXT NOT NULL REFERENCES public.profiles(id),
    task_id TEXT REFERENCES public.tasks(id),
    coords JSONB NOT NULL,
    speed_kmh NUMERIC(5, 2),
    heading_deg NUMERIC(5, 2),
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- RLS CONFIGURATION & DEMO API PERMISSIONS
-- ====================================================================
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.fraud_cases DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.runner_telemetry DISABLE ROW LEVEL SECURITY;

GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

-- ====================================================================
-- PERFORMANCE INDEXES
-- ====================================================================
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_requester ON public.tasks(requester_id);
CREATE INDEX IF NOT EXISTS idx_tasks_runner ON public.tasks(runner_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created ON public.transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_fraud_featured ON public.fraud_cases(featured);
CREATE INDEX IF NOT EXISTS idx_telemetry_runner_time ON public.runner_telemetry(runner_id, recorded_at DESC);

-- ====================================================================
-- STORED PROCEDURES / RPC FUNCTIONS FOR ATOMIC ESCROW SETTLEMENT
-- ====================================================================

CREATE OR REPLACE FUNCTION public.fn_lock_task_escrow(
    p_user_id TEXT,
    p_task_id TEXT,
    p_amount NUMERIC
) RETURNS JSONB AS $$
DECLARE
    v_available NUMERIC;
    v_tx_id TEXT;
BEGIN
    SELECT available_tokens INTO v_available
    FROM public.wallets
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF v_available IS NULL OR v_available < p_amount THEN
        RAISE EXCEPTION 'Insufficient tokens. Available: %, Required: %', COALESCE(v_available, 0), p_amount;
    END IF;

    UPDATE public.wallets
    SET available_tokens = available_tokens - p_amount,
        escrow_locked = escrow_locked + p_amount,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    v_tx_id := 'tx-lock-' || p_task_id || '-' || floor(random() * 9000 + 1000)::TEXT;

    INSERT INTO public.transactions (id, user_id, type, tokens, reference, reference_task_id, status)
    VALUES (v_tx_id, p_user_id, 'ESCROW_LOCK', -p_amount, 'Task ' || p_task_id || ' bounty locked in escrow', p_task_id, 'COMPLETED');

    RETURN jsonb_build_object(
        'success', true,
        'userId', p_user_id,
        'taskId', p_task_id,
        'lockedAmount', p_amount,
        'transactionId', v_tx_id
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.fn_release_task_escrow(
    p_task_id TEXT
) RETURNS JSONB AS $$
DECLARE
    v_task RECORD;
BEGIN
    SELECT * INTO v_task
    FROM public.tasks
    WHERE id = p_task_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Task % not found', p_task_id;
    END IF;

    UPDATE public.wallets
    SET escrow_locked = GREATEST(0, escrow_locked - v_task.wager),
        updated_at = NOW()
    WHERE user_id = v_task.requester_id;

    UPDATE public.wallets
    SET available_tokens = available_tokens + v_task.wager + v_task.runner_stake_locked,
        runner_staked = GREATEST(0, runner_staked - v_task.runner_stake_locked),
        updated_at = NOW()
    WHERE user_id = v_task.runner_id;

    UPDATE public.tasks
    SET status = 'COMPLETED',
        completed_at = NOW()
    WHERE id = p_task_id;

    INSERT INTO public.transactions (id, user_id, type, tokens, reference, reference_task_id, status)
    VALUES
        ('tx-rel-' || p_task_id, v_task.requester_id, 'ESCROW_RELEASE', 0, 'Task ' || p_task_id || ' settled', p_task_id, 'COMPLETED'),
        ('tx-bounty-' || p_task_id, v_task.runner_id, 'BOUNTY_PAYOUT', v_task.wager, 'Task ' || p_task_id || ' bounty paid', p_task_id, 'COMPLETED'),
        ('tx-stk-ret-' || p_task_id, v_task.runner_id, 'STAKE_RETURN', v_task.runner_stake_locked, 'Task ' || p_task_id || ' stake returned', p_task_id, 'COMPLETED');

    UPDATE public.profiles
    SET completed_tasks = completed_tasks + 1
    WHERE id = v_task.runner_id;

    RETURN jsonb_build_object(
        'success', true,
        'taskId', p_task_id,
        'bountyPaid', v_task.wager,
        'stakeReturned', v_task.runner_stake_locked
    );
END;
$$ LANGUAGE plpgsql;

-- ====================================================================
-- SEED DATA (VIT Vellore Campus Profiles, Wallets & 24 Locations)
-- ====================================================================
INSERT INTO public.profiles (id, reg_number, reg_hash, name, hostel_block, trust_score, completed_tasks, is_restricted, role)
VALUES
    ('usr-rohit', '22BCE1142', '22BCE****', 'Rohit Verma', 'Q Block', 4.90, 34, FALSE, 'student'),
    ('usr-rohan', '22BEE0819', '22BEE****', 'Rohan Mehta', 'P Block', 4.80, 52, FALSE, 'runner'),
    ('usr-rahul', '22BCE0089', '22BCE****', 'Rahul S.', 'Q Block', 1.20, 8, TRUE, 'student'),
    ('usr-proctor', 'PROCTOR-01', 'ADMIN****', 'Student Proctor Ops', 'Main Building', 5.00, 0, FALSE, 'admin')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.wallets (user_id, available_tokens, escrow_locked, runner_staked)
VALUES
    ('usr-rohit', 85.00, 0.00, 0.00),
    ('usr-rohan', 140.00, 0.00, 0.00),
    ('usr-rahul', 0.00, 0.00, 0.00),
    ('usr-proctor', 1000.00, 0.00, 0.00)
ON CONFLICT (user_id) DO NOTHING;

-- Seed All 24 VIT Locations
INSERT INTO public.locations (id, name, category, coords, popular_for)
VALUES
    ('loc-main-gate', 'Main Gate Katpadi Entrance', 'gate', '[12.9692, 79.1559]', 'Swiggy/Zomato parcel pickup & auto stand'),
    ('loc-gate-2', 'Gate 2 (Chittoor Bus Stand Road)', 'gate', '[12.9734, 79.1637]', 'Bus station access & fast parcel drops'),
    ('loc-gate-3', 'Gate 3 (Railway Side Entrance)', 'gate', '[12.9680, 79.1585]', 'Katpadi junction pedestrian corridor'),
    ('loc-sjt', 'Silver Jubilee Tower (SJT)', 'academic', '[12.9710, 79.1635]', 'CSE/IT theory & computing lab classes'),
    ('loc-tt', 'Technology Tower (TT) & Portico', 'academic', '[12.9702, 79.1594]', 'Dean offices, auditoriums & tech clubs'),
    ('loc-tt-xerox', 'TT Ground Floor Central Xerox', 'facility', '[12.9701, 79.1592]', 'Urgent lab record printing & spiral binding'),
    ('loc-mb', 'Main Building (Dr. MGR Block)', 'academic', '[12.9696, 79.1578]', 'Admissions, administrative desks & banks'),
    ('loc-smv', 'SMV Engineering Block', 'academic', '[12.9699, 79.1583]', 'Electrical & Mechanical laboratories'),
    ('loc-cdmm', 'CDMM Mechanical Block', 'academic', '[12.9694, 79.1599]', 'Design studios & workshop halls'),
    ('loc-anna-audi', 'Anna Auditorium Hexagon', 'facility', '[12.9698, 79.1568]', 'Cultural festivals, convocations & hackathons'),
    ('loc-periyar-lib', 'Periyar Central Library', 'academic', '[12.9695, 79.1564]', 'Quiet air-conditioned study rooms & archives'),
    ('loc-gazebo', 'Gazebo Food Court & Juice Bar', 'food', '[12.9705, 79.1601]', 'Fresh juices, shawarma & evening snacks'),
    ('loc-foody-st', 'Foody Street Campus Boulevard', 'food', '[12.9707, 79.1608]', 'Multi-cuisine street dining stalls'),
    ('loc-darling-bakery', 'Darling Bakery & Coffee Portico', 'food', '[12.9698, 79.1588]', 'Puffs, cakes & cold filter coffee'),
    ('loc-enzymes', 'Enzymes Canteen (Near SJT)', 'food', '[12.9713, 79.1630]', 'Quick breakfast dosas & iced teas'),
    ('loc-health-centre', 'VIT Central Health Centre & Pharmacy', 'facility', '[12.9712, 79.1614]', '24/7 medical emergency & medicines'),
    ('loc-swimming-pool', 'Olympic Sports Complex & Pool', 'facility', '[12.9720, 79.1610]', 'Gym, badminton courts & athletics track'),
    ('loc-p-block', 'P Block Men''s Hostel', 'hostel', '[12.9718, 79.1619]', 'Residential block & indoor table tennis'),
    ('loc-q-block', 'Q Block Men''s Residential Tower', 'hostel', '[12.9726, 79.1624]', 'High-rise hostel tower with campus night cafe'),
    ('loc-k-block', 'K Block Men''s Hostel', 'hostel', '[12.9709, 79.1622]', 'Junior residential hostel wing'),
    ('loc-l-block', 'L Block Men''s Hostel', 'hostel', '[12.9714, 79.1625]', 'Hostel block close to swimming pool'),
    ('loc-ladies-hostel', 'LH Central Security Turnstile', 'hostel', '[12.9687, 79.1575]', 'Women''s hostel main checkpoint'),
    ('loc-all-mart', 'All Mart Campus Supermarket', 'facility', '[12.9710, 79.1617]', 'Daily toiletries, stationery & snacks'),
    ('loc-post-office', 'Campus Post Office & SBI Bank', 'facility', '[12.9691, 79.1568]', 'Postal deliveries, packages & ATM')
ON CONFLICT (id) DO NOTHING;

-- Seed Initial Tasks
INSERT INTO public.tasks (id, title, category, requester_id, requester_name, requester_trust_score, pickup_node_id, pickup_node_name, pickup_coords, drop_node_id, drop_node_name, drop_coords, wager, notes, urgency, status, pickup_otp, delivery_otp)
VALUES
    ('TSK-101', 'Pick up Darling Bakery Veg Puff & Cold Coffee', 'food', 'usr-rohit', 'Rohit Verma', 4.90, 'loc-darling-bakery', 'Darling Bakery & Coffee Portico', '[12.9698, 79.1588]', 'loc-q-block', 'Q Block Men''s Residential Tower', '[12.9726, 79.1624]', 18.00, 'Keep cold coffee upright. Call at security gate.', 'normal', 'OPEN', '4821', '7392'),
    ('TSK-102', 'Collect 12-page Thermal Lab report printout', 'facility', 'usr-rohit', 'Rohit Verma', 4.90, 'loc-tt-xerox', 'TT Ground Floor Central Xerox', '[12.9701, 79.1592]', 'loc-sjt', 'Silver Jubilee Tower (SJT)', '[12.9710, 79.1635]', 14.00, 'Token #34 paid already at shop counter.', 'urgent', 'OPEN', '3159', '9841')
ON CONFLICT (id) DO NOTHING;

-- Seed Initial Fraud Case
INSERT INTO public.fraud_cases (id, user_id, user_name, reg_hash, title, status, featured, microcopy, penalty, trust_shield_evidence)
VALUES (
    'FRD-2026-089',
    'usr-rahul',
    'Rahul S.',
    '22BCE****',
    'The Great Pizza Phantom Hand-off',
    'CONFIRMED VIOLATION',
    'day',
    'OMW remembers. Not the route we recommended.',
    '{"tokensForfeited": 85, "restrictionType": "PERMANENT_ESCROW_LOCK", "proctorNotes": "Simultaneous dual-OTP submission from same cell tower with zero GPS delta."}',
    '{"expectedDistanceMeters": 1420, "recordedTimeSeconds": 8, "computedSpeedKmh": 639.0, "routeDeviationPercent": 99.4, "deviceFingerprintMatch": true, "confirmedAt": "2026-09-18T14:22:00Z"}'
)
ON CONFLICT (id) DO NOTHING;
