import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
  const sql = postgres(process.env.DATABASE_URL!);
  const db = drizzle(sql);
  
  try {
    await sql`ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_otp text;`;
    await sql`ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_otp_expires_at timestamp;`;
    console.log('Columns added successfully in DB');
  } catch (error: any) {
    console.log('Column add failed:', error.message);
  }
  
  process.exit(0);
}

main();
