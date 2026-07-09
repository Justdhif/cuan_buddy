ALTER TABLE "savings_goals" DROP CONSTRAINT "savings_goals_user_id_slug_unique";--> statement-breakpoint
ALTER TABLE "categories" DROP COLUMN "slug";--> statement-breakpoint
ALTER TABLE "savings_goals" DROP COLUMN "slug";