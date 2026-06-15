import { neon } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-http';
import * as dotenv from 'dotenv';
import { categories } from './src/database/schema';

dotenv.config();

const sql = neon(process.env.DATABASE_URL!);
const db = drizzle(sql);

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
  console.log('🌱 Seeding categories...');
  for (const cat of defaultCategories) {
    await db.insert(categories).values(cat).execute();
  }
  console.log('✅ Seeding complete!');
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌ Seeding failed:', err);
  process.exit(1);
});
