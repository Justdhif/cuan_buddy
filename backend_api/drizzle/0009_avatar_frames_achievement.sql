-- Migration: Add avatar frame achievement columns to user_profiles
-- 0009_avatar_frames_achievement.sql

ALTER TABLE "user_profiles" ADD COLUMN IF NOT EXISTS "unlocked_borders" jsonb DEFAULT '[]'::jsonb;
ALTER TABLE "user_profiles" ADD COLUMN IF NOT EXISTS "recording_streak_count" integer DEFAULT 0 NOT NULL;
ALTER TABLE "user_profiles" ADD COLUMN IF NOT EXISTS "last_recorded_at" timestamp;
