-- ====================================================================
-- OMW Migration 002: Google OAuth, VIT Student Parser & Promotional Airdrop
-- Target Campus: Vellore Institute of Technology (VIT Vellore)
-- ====================================================================

-- 1. Extend PROFILES with VIT email and academic standing
ALTER TABLE IF EXISTS public.profiles 
ADD COLUMN IF NOT EXISTS email TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS admission_year INTEGER,
ADD COLUMN IF NOT EXISTS academic_standing TEXT;

-- 2. Extend WALLETS with bonus (non-cashable) and cashable token balances
ALTER TABLE IF EXISTS public.wallets
ADD COLUMN IF NOT EXISTS bonus_tokens NUMERIC(12, 2) DEFAULT 0.00 CHECK (bonus_tokens >= 0),
ADD COLUMN IF NOT EXISTS cashable_tokens NUMERIC(12, 2) DEFAULT 0.00 CHECK (cashable_tokens >= 0);

-- Backfill existing wallets: set cashable_tokens equal to available_tokens
UPDATE public.wallets
SET cashable_tokens = available_tokens
WHERE cashable_tokens = 0.00 AND available_tokens > 0;

-- 3. Extend TRANSACTIONS check constraint to include 'AIRDROP_BONUS'
ALTER TABLE IF EXISTS public.transactions 
DROP CONSTRAINT IF EXISTS transactions_type_check;

ALTER TABLE IF EXISTS public.transactions
ADD CONSTRAINT transactions_type_check CHECK (type IN (
    'TOKEN_PURCHASE',
    'ESCROW_LOCK',
    'RUNNER_STAKE_LOCK',
    'ESCROW_RELEASE',
    'BOUNTY_PAYOUT',
    'STAKE_RETURN',
    'ESCROW_REFUND',
    'STAKE_SLASHED',
    'FIAT_WITHDRAWAL',
    'VOUCHER_REDEMPTION',
    'AIRDROP_BONUS'
));

-- 4. Update seed users with VIT emails
UPDATE public.profiles
SET email = 'rohit.verma2024@vitstudent.ac.in',
    admission_year = 2024,
    academic_standing = '3rd Year (Junior)'
WHERE id = 'usr-rohit' AND email IS NULL;

UPDATE public.profiles
SET email = 'rohan.sharma2025@vitstudent.ac.in',
    admission_year = 2025,
    academic_standing = '2nd Year (Sophomore)'
WHERE id = 'usr-rohan' AND email IS NULL;
