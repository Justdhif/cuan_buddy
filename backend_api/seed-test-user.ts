import { neon } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-http';
import * as dotenv from 'dotenv';
import * as schema from './src/database/schema';
import * as bcrypt from 'bcrypt';

dotenv.config();

const sql = neon(process.env.DATABASE_URL!);
const db = drizzle(sql, { schema });

const targetEmail = 'justdhif418@gmail.com';
const rawPassword = 'admin123';

const allBorderIds = [
  'none',
  'border-1',
  'border-2',
  'border-rookie',
  'border-first-goal',
  'border-cuan-planner',
  'border-cuan-partner',
  'border-master-saver',
  'border-budget-master',
  'border-tracker-pro',
  'border-consistency',
  'border-cuan-emperor'
];

async function seedTestUser() {
  console.log(`🔍 Memeriksa apakah user ${targetEmail} sudah ada...`);

  // Kita gunakan raw query atau direct db select dengan schema.users untuk menghindari mismatch typing drizzle
  const allUsers = await db.select().from(schema.users);
  let user = allUsers.find(u => u.email === targetEmail);

  const passwordHash = await bcrypt.hash(rawPassword, 10);

  if (!user) {
    console.log(`🌱 Membuat user baru...`);
    const [newUser] = await db
      .insert(schema.users)
      .values({
        email: targetEmail,
        passwordHash,
        isActive: true,
        provider: 'local',
      })
      .returning();
    user = newUser;
    console.log(`✅ User berhasil dibuat dengan ID: ${user.id}`);
  } else {
    console.log(`⚠️ User sudah terdaftar. Mengupdate password...`);
    // Lakukan raw SQL update untuk menghindari error typing drizzle-orm
    await sql`UPDATE users SET password_hash = ${passwordHash}, updated_at = NOW() WHERE id = ${user.id}`;
    console.log(`✅ Password berhasil diperbarui.`);
  }

  // Ambil profile
  const allProfiles = await db.select().from(schema.userProfiles);
  const existingProfile = allProfiles.find(p => p.userId === user!.id);

  if (!existingProfile) {
    console.log(`🌱 Membuat profil baru dengan unlockedBorders lengkap...`);
    await db.insert(schema.userProfiles).values({
      userId: user.id,
      fullName: 'Dhif Cuan Buddy',
      username: 'justdhif418',
      bio: 'Akun testing untuk verifikasi semua bingkai border avatar premium 🚀',
      gender: 'male',
      avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=justdhif',
      avatarBorder: 'border-rookie',
      unlockedBorders: allBorderIds,
      recordingStreakCount: 30,
      language: 'id',
    });
    console.log(`✅ Profil berhasil dibuat dengan semua border ter-unlock.`);
  } else {
    console.log(`⚠️ Profil sudah ada. Mengupdate list unlocked_borders agar berisi semua border...`);
    // Gunakan raw query sql untuk update demi keandalan kompilasi
    const bordersJson = JSON.stringify(allBorderIds);
    await sql`
      UPDATE user_profiles 
      SET unlocked_borders = ${bordersJson}::jsonb, 
          full_name = 'Dhif Cuan Buddy', 
          username = 'justdhif418', 
          bio = 'Akun testing untuk verifikasi semua bingkai border avatar premium 🚀', 
          updated_at = NOW() 
      WHERE user_id = ${user.id}
    `;
    console.log(`✅ Profil berhasil diperbarui dengan semua border ter-unlock.`);
  }

  console.log('\n🎉 Selesai! Silakan login di aplikasi dengan email dan password tersebut.');
  process.exit(0);
}

seedTestUser().catch((err) => {
  console.error('❌ Seeding gagal:', err);
  process.exit(1);
});
