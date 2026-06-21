import 'dotenv/config';
import { neon } from '@neondatabase/serverless';
import { execSync } from 'child_process';

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  console.error('DATABASE_URL is not defined in the environment.');
  process.exit(1);
}

const sql = neon(databaseUrl);

async function main() {
  console.log('🗑️ Dropping public schema...');
  try {
    await sql`DROP SCHEMA public CASCADE;`;
    await sql`CREATE SCHEMA public;`;
    console.log('✅ Public schema dropped and recreated.');
  } catch (error) {
    console.error('Failed to drop schema:', error);
    process.exit(1);
  }

  console.log('\n🚀 Pushing schema via drizzle-kit...');
  try {
    execSync('npx drizzle-kit push', { stdio: 'inherit' });
    console.log('✅ Schema pushed successfully.');
  } catch (error) {
    console.error('Failed to push schema:', error);
    process.exit(1);
  }

  console.log('\n🌱 Seeding database...');
  try {
    execSync('npx tsx seed.ts', { stdio: 'inherit' });
    console.log('✅ Database seeded successfully.');
  } catch (error) {
    console.error('Failed to seed database:', error);
    process.exit(1);
  }

  console.log('\n✨ Migrate fresh completed successfully!');
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
