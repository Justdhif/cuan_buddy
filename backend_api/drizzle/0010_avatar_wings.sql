-- Migration: Add avatar_wings column to user_profiles
-- 0010_avatar_wings.sql

ALTER TABLE "user_profiles" ADD COLUMN IF NOT EXISTS "avatar_wings" text;
