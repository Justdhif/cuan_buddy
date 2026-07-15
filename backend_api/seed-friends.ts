import { neon } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-http';
import * as dotenv from 'dotenv';
import * as schema from './src/database/schema';
import * as bcrypt from 'bcrypt';

dotenv.config();

const sql = neon(process.env.DATABASE_URL!);
const db = drizzle(sql, { schema });

// UUID user yang sudah ada dan akan dijadikan teman
const TARGET_USER_ID = '1d6057af-1469-40ca-83a9-397d01b89bda';

const dummyUsers = [
  {
    email: 'budi.santoso@example.com',
    fullName: 'Budi Santoso',
    username: 'budisantoso',
    bio: 'Suka ngopi dan coding di sore hari ☕',
    gender: 'male',
    avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=budi',
    avatarBorder: 'border-1',
  },
  {
    email: 'siti.rahayu@example.com',
    fullName: 'Siti Rahayu',
    username: 'sitirahayu',
    bio: 'Traveler dan food blogger 🌍',
    gender: 'female',
    avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=siti',
    avatarBorder: 'border-2',
  },
  {
    email: 'agus.wirawan@example.com',
    fullName: 'Agus Wirawan',
    username: 'aguswirawan',
    bio: 'Penggemar musik indie dan pecinta kucing 🐱',
    gender: 'male',
    avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=agus',
    avatarBorder: null,
  },
  {
    email: 'dewi.lestari@example.com',
    fullName: 'Dewi Lestari',
    username: 'dewilestari_',
    bio: 'Designer grafis freelance dan pecinta seni 🎨',
    gender: 'female',
    avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=dewi',
    avatarBorder: 'border-1',
  },
  {
    email: 'eko.prasetyo@example.com',
    fullName: 'Eko Prasetyo',
    username: 'ekoprasetyo',
    bio: 'Backend developer yang gemar bersepeda 🚴',
    gender: 'male',
    avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=eko',
    avatarBorder: 'border-2',
  },
  {
    email: 'fitri.handayani@example.com',
    fullName: 'Fitri Handayani',
    username: 'fitrihandayani',
    bio: 'Ibu rumah tangga yang aktif berolahraga 💪',
    gender: 'female',
    avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=fitri',
    avatarBorder: null,
  },
  {
    email: 'galih.permana@example.com',
    fullName: 'Galih Permana',
    username: 'galihpermana',
    bio: 'Startup founder dan mentor UMKM 🚀',
    gender: 'male',
    avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=galih',
    avatarBorder: 'border-1',
  },
  {
    email: 'hana.pertiwi@example.com',
    fullName: 'Hana Pertiwi',
    username: 'hanapertiwi',
    bio: 'Content creator lifestyle dan kecantikan ✨',
    gender: 'female',
    avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=hana',
    avatarBorder: 'border-2',
  },
  {
    email: 'irfan.maulana@example.com',
    fullName: 'Irfan Maulana',
    username: 'irfanmaulana',
    bio: 'Mahasiswa teknik yang gemar riset dan nulis 📚',
    gender: 'male',
    avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=irfan',
    avatarBorder: null,
  },
  {
    email: 'julia.anggraini@example.com',
    fullName: 'Julia Anggraini',
    username: 'juliaanggraini',
    bio: 'Dokter muda yang hobi masak dan berkebun 🌿',
    gender: 'female',
    avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=julia',
    avatarBorder: 'border-1',
  },
];

const defaultCategories = [
  { name: 'Food', emojiIcon: '🍔', colorCode: '#FF5733' },
  { name: 'Transport', emojiIcon: '🚕', colorCode: '#FFC300' },
  { name: 'Entertainment', emojiIcon: '🎮', colorCode: '#900C3F' },
  { name: 'Shopping', emojiIcon: '🛍', colorCode: '#DAF7A6' },
  { name: 'Bills', emojiIcon: '💡', colorCode: '#581845' },
  { name: 'Salary', emojiIcon: '💼', colorCode: '#2ECC71' },
  { name: 'Bonus', emojiIcon: '🎁', colorCode: '#F1C40F' },
  { name: 'Investment', emojiIcon: '📈', colorCode: '#3498DB' },
  { name: 'Others', emojiIcon: '📦', colorCode: '#95A5A6' },
];

async function seedFriends() {
  console.log('🔍 Memeriksa target user...');

  const targetUser = await db.query.users.findFirst({
    where: (u, { eq }) => eq(u.id, TARGET_USER_ID),
  });

  if (!targetUser) {
    console.error(`❌ Target user dengan ID ${TARGET_USER_ID} tidak ditemukan!`);
    process.exit(1);
  }

  console.log(`✅ Target user ditemukan: ${targetUser.email}`);

  const passwordHash = await bcrypt.hash('Password123!', 10);

  for (const data of dummyUsers) {
    console.log(`\n👤 Membuat user: ${data.fullName} (${data.email})`);

    // Cek apakah user sudah ada
    let user = await db.query.users.findFirst({
      where: (u, { eq }) => eq(u.email, data.email),
    });

    if (!user) {
      const [newUser] = await db
        .insert(schema.users)
        .values({
          email: data.email,
          passwordHash,
          isActive: true,
          provider: 'local',
        })
        .returning();
      user = newUser;
      console.log(`   ✅ User dibuat: ${user.id}`);
    } else {
      console.log(`   ⚠️  User sudah ada: ${user.id}`);
    }

    // Cek / buat profil
    const existingProfile = await db.query.userProfiles.findFirst({
      where: (p, { eq }) => eq(p.userId, user!.id),
    });

    if (!existingProfile) {
      await db.insert(schema.userProfiles).values({
        userId: user.id,
        fullName: data.fullName,
        username: data.username,
        bio: data.bio,
        gender: data.gender,
        avatar: data.avatar,
        avatarBorder: data.avatarBorder,
        language: 'id',
      });
      console.log(`   ✅ Profil dibuat untuk ${data.fullName}`);
    } else {
      console.log(`   ⚠️  Profil sudah ada, skip.`);
    }

    // Buat default categories untuk user baru
    for (const cat of defaultCategories) {
      const existingCat = await db.query.categories.findFirst({
        where: (c, { and, eq }) =>
          and(eq(c.userId, user!.id), eq(c.name, cat.name)),
      });
      if (!existingCat) {
        await db.insert(schema.categories).values({ ...cat, userId: user.id });
      }
    }
    console.log(`   ✅ Default categories dibuat`);

    // Cek / buat friendship dengan target user
    const existingFriendship = await db.query.friendships.findFirst({
      where: (f, { or, and, eq }) =>
        or(
          and(eq(f.senderId, TARGET_USER_ID), eq(f.receiverId, user!.id)),
          and(eq(f.senderId, user!.id), eq(f.receiverId, TARGET_USER_ID)),
        ),
    });

    if (!existingFriendship) {
      await db.insert(schema.friendships).values({
        senderId: TARGET_USER_ID,
        receiverId: user.id,
        status: 'accepted',
      });
      console.log(`   ✅ Friendship dibuat (accepted) dengan target user`);
    } else {
      console.log(`   ⚠️  Friendship sudah ada (status: ${existingFriendship.status})`);
    }
  }

  console.log('\n🎉 Seeding selesai! 10 teman dummy berhasil dibuat.');
  process.exit(0);
}

seedFriends().catch((err) => {
  console.error('❌ Seeding gagal:', err);
  process.exit(1);
});
