-- Migration: Consolidate WhatsApp fields - move waConnectOtp to user_profiles, use phone_number as single WA phone field
-- 0013_consolidate_wa_fields.sql

-- Remove redundant WA columns from users table
ALTER TABLE "users" DROP COLUMN IF EXISTS "wa_connect_otp";
ALTER TABLE "users" DROP COLUMN IF EXISTS "whatsapp_phone";

-- Add waConnectOtp to user_profiles (temporary OTP for WA pairing)
ALTER TABLE "user_profiles" ADD COLUMN IF NOT EXISTS "wa_connect_otp" text;

-- Add UNIQUE constraint to phone_number in user_profiles (if not already)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'user_profiles_phone_number_unique'
  ) THEN
    ALTER TABLE "user_profiles" ADD CONSTRAINT "user_profiles_phone_number_unique" UNIQUE ("phone_number");
  END IF;
END
$$;
