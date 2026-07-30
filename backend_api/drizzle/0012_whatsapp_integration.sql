-- Migration: Add WhatsApp Integration columns to users table
-- 0012_whatsapp_integration.sql

ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "wa_connect_otp" text;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "whatsapp_phone" text UNIQUE;
