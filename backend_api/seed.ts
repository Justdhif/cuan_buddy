import { neon } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-http';
import * as dotenv from 'dotenv';
import * as schema from './src/database/schema';
import { and, eq } from 'drizzle-orm';

dotenv.config();

const sql = neon(process.env.DATABASE_URL!);
const db = drizzle(sql, { schema });

const defaultCategories = [
  { slug: 'food', name: 'Food', emojiIcon: '🍔', colorCode: '#FF5733' },
  { slug: 'transport', name: 'Transport', emojiIcon: '🚕', colorCode: '#FFC300' },
  { slug: 'entertainment', name: 'Entertainment', emojiIcon: '🎮', colorCode: '#900C3F' },
  { slug: 'shopping', name: 'Shopping', emojiIcon: '🛍', colorCode: '#DAF7A6' },
  { slug: 'bills', name: 'Bills', emojiIcon: '💡', colorCode: '#581845' },
  { slug: 'salary', name: 'Salary', emojiIcon: '💼', colorCode: '#2ECC71' },
  { slug: 'bonus', name: 'Bonus', emojiIcon: '🎁', colorCode: '#F1C40F' },
  { slug: 'investment', name: 'Investment', emojiIcon: '📈', colorCode: '#3498DB' },
];

async function seed() {
  console.log('🌱 Seeding categories for all users...');
  
  const allUsers = await db.select().from(schema.users);
  
  if (allUsers.length === 0) {
    console.log('⚠️ No users found in database. Please register a user first before seeding.');
    process.exit(0);
  }

  for (const user of allUsers) {
    console.log(`Adding categories for user: ${user.email}`);
    for (const cat of defaultCategories) {
      try {
        // Check if category already exists for this user
        const existing = await db.query.categories.findFirst({
          where: and(eq(schema.categories.slug, cat.slug), eq(schema.categories.userId, user.id))
        });

        if (!existing) {
          await db.insert(schema.categories).values({
            ...cat,
            userId: user.id
          }).execute();
        }
      } catch (e) {
        console.error(`Failed to add ${cat.slug} for ${user.email}:`, e);
      }
    }
  }

  console.log('✅ Seeding complete!');
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌ Seeding failed:', err);
  process.exit(1);
});
