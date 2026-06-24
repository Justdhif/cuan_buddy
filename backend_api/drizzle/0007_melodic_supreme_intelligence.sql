ALTER TABLE "budgets" ALTER COLUMN "limit_amount" SET DATA TYPE numeric(19, 2);--> statement-breakpoint
ALTER TABLE "budgets" ALTER COLUMN "rollover_amount" SET DATA TYPE numeric(19, 2);--> statement-breakpoint
ALTER TABLE "budgets" ALTER COLUMN "rollover_amount" SET DEFAULT '0';--> statement-breakpoint
ALTER TABLE "savings_goals" ALTER COLUMN "target_amount" SET DATA TYPE numeric(19, 2);--> statement-breakpoint
ALTER TABLE "savings_goals" ALTER COLUMN "current_amount" SET DATA TYPE numeric(19, 2);--> statement-breakpoint
ALTER TABLE "savings_goals" ALTER COLUMN "current_amount" SET DEFAULT '0';--> statement-breakpoint
ALTER TABLE "transactions" ALTER COLUMN "amount" SET DATA TYPE numeric(19, 2);--> statement-breakpoint
ALTER TABLE "transactions" ADD COLUMN "title" text;--> statement-breakpoint
ALTER TABLE "transactions" ADD COLUMN "savings_goal_id" uuid;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_savings_goal_id_savings_goals_id_fk" FOREIGN KEY ("savings_goal_id") REFERENCES "public"."savings_goals"("id") ON DELETE set null ON UPDATE no action;