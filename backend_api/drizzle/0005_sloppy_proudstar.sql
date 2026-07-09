ALTER TABLE "savings_goals" DROP CONSTRAINT "savings_goals_slug_unique";--> statement-breakpoint
ALTER TABLE "savings_goals" ALTER COLUMN "slug" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "savings_goals" ADD CONSTRAINT "savings_goals_user_id_slug_unique" UNIQUE("user_id","slug");