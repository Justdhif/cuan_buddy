import { neon } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-http';
import * as dotenv from 'dotenv';
import * as schema from './src/database/schema';

dotenv.config();
const sql = neon(process.env.DATABASE_URL!);
const db = drizzle(sql, { schema });

const userId = '1d6057af-1469-40ca-83a9-397d01b89bda';

async function seedData() {
  console.log('🌱 Menyiapkan data pencapaian untuk user justdhif418@gmail.com...');

  console.log('💰 Membuat data Saving Goals...');

  await sql`DELETE FROM savings_goals WHERE user_id = ${userId}`;

  // Sisipkan saving goals baru
  // completed saving goals
  for (let i = 1; i <= 5; i++) {
    await db.insert(schema.savingsGoals).values({
      userId,
      name: `Tabungan Selesai ${i}`,
      targetAmount: '2000000',
      currentAmount: '2000000',
      status: 'completed',
      colorCode: '#4CAF50',
      createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // 30 hari lalu
    });
  }

  // active/in_progress saving goals
  for (let i = 1; i <= 3; i++) {
    await db.insert(schema.savingsGoals).values({
      userId,
      name: `Tabungan Aktif ${i}`,
      targetAmount: '5000000',
      currentAmount: '1500000',
      status: 'in_progress',
      colorCode: '#2196F3',
    });
  }

  // 2. Set streak count di user profile menjadi 30 hari dan set tanggal registrasi 6 bulan lalu
  console.log('👤 Mengupdate profil user...');
  const sixMonthsAgo = new Date();
  sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 7);

  await sql`
    UPDATE user_profiles
    SET recording_streak_count = 35,
        created_at = ${sixMonthsAgo.toISOString()}
    WHERE user_id = ${userId}
  `;

  console.log('✅ Semua data dummy pencapaian berhasil dibuat!');
  process.exit(0);
}

seedData().catch(console.error);
