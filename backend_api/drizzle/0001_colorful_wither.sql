ALTER TABLE "users" ADD COLUMN "reset_otp" text;--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "reset_otp_expires_at" timestamp;