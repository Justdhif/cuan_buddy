import { neon } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-http';
import * as dotenv from 'dotenv';
import * as schema from './src/database/schema';
import * as bcrypt from 'bcrypt';
import { eq, and } from 'drizzle-orm';

dotenv.config();

const sql = neon(process.env.DATABASE_URL!);
const db = drizzle(sql, { schema });

const dummyMembers = [
  {
    email: 'budi.santoso@example.com',
    fullName: 'Budi Santoso',
    username: 'budisantoso',
    avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=budi',
  },
  {
    email: 'siti.rahayu@example.com',
    fullName: 'Siti Rahayu',
    username: 'sitirahayu',
    avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=siti',
  },
  {
    email: 'agus.wirawan@example.com',
    fullName: 'Agus Wirawan',
    username: 'aguswirawan',
    avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=agus',
  },
  {
    email: 'dewi.lestari@example.com',
    fullName: 'Dewi Lestari',
    username: 'dewilestari_',
    avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=dewi',
  },
  {
    email: 'eko.prasetyo@example.com',
    fullName: 'Eko Prasetyo',
    username: 'ekoprasetyo',
    avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=eko',
  },
];

async function seedSharedRooms() {
  console.log('🌱 Starting Shared Rooms Seeding process...');

  const allUsers = await db.select().from(schema.users);
  if (allUsers.length === 0) {
    console.error('❌ Tidak ada user di database! Silakan daftarkan user terlebih dahulu.');
    process.exit(1);
  }

  let mainUser = allUsers.find((u) => u.email === 'justdhif418@gmail.com') || allUsers[0];
  console.log(`👤 Target Main User: ${mainUser.email} (ID: ${mainUser.id})`);

  // Ensure main user profile exists
  let mainProfile = await db.query.userProfiles.findFirst({
    where: (p, { eq }) => eq(p.userId, mainUser.id),
  });
  if (!mainProfile) {
    await db.insert(schema.userProfiles).values({
      userId: mainUser.id,
      fullName: 'Dhif Cuan Buddy',
      username: 'justdhif418',
      avatar: 'https://api.dicebear.com/8.x/avataaars/png?seed=justdhif',
      language: 'id',
    });
  }

  // Ensure main user wallet exists
  let mainWallet = await db.query.wallets.findFirst({
    where: (w, { eq }) => eq(w.userId, mainUser.id),
  });
  if (!mainWallet) {
    const [w] = await db
      .insert(schema.wallets)
      .values({
        userId: mainUser.id,
        name: 'Dompet Utama',
        emojiIcon: '👛',
        colorCode: '#6C63FF',
        type: 'cash',
        currency: 'IDR',
        isBaseCurrency: true,
        balance: '5000000',
      })
      .returning();
    mainWallet = w;
  }

  // Ensure default categories exist for main user
  let categoryMap: Record<string, string> = {};
  const existingCats = await db.query.categories.findMany({
    where: (c, { eq }) => eq(c.userId, mainUser.id),
  });
  for (const cat of existingCats) {
    categoryMap[cat.name] = cat.id;
  }

  const defaultCats = [
    { name: 'Food', emojiIcon: '🍔', colorCode: '#FF5733' },
    { name: 'Transport', emojiIcon: '🚕', colorCode: '#FFC300' },
    { name: 'Entertainment', emojiIcon: '🎮', colorCode: '#900C3F' },
    { name: 'Shopping', emojiIcon: '🛍', colorCode: '#DAF7A6' },
    { name: 'Bills', emojiIcon: '💡', colorCode: '#581845' },
  ];

  for (const cat of defaultCats) {
    if (!categoryMap[cat.name]) {
      const [c] = await db
        .insert(schema.categories)
        .values({
          userId: mainUser.id,
          name: cat.name,
          emojiIcon: cat.emojiIcon,
          colorCode: cat.colorCode,
        })
        .returning();
      categoryMap[cat.name] = c.id;
    }
  }

  // 2. Create or fetch dummy member users
  const passwordHash = await bcrypt.hash('Password123!', 10);
  const createdMemberUsers: Array<typeof schema.users.$inferSelect> = [];

  for (const dummy of dummyMembers) {
    let u = allUsers.find((user) => user.email === dummy.email);
    if (!u) {
      const [newUser] = await db
        .insert(schema.users)
        .values({
          email: dummy.email,
          passwordHash,
          isActive: true,
          provider: 'local',
        })
        .returning();
      u = newUser;

      await db.insert(schema.userProfiles).values({
        userId: u.id,
        fullName: dummy.fullName,
        username: dummy.username,
        avatar: dummy.avatar,
        language: 'id',
      });
    }
    createdMemberUsers.push(u);
  }

  console.log(`✅ Loaded ${createdMemberUsers.length} member dummy users.`);

  // 3. Define Rooms to Seed
  const roomDefinitions = [
    {
      name: 'Liburan Bali 🏖️',
      emojiIcon: '🏖️',
      colorCode: '#00B4D8',
      description: 'Patungan liburan seru ke Bali bareng teman-teman',
      owner: mainUser,
      members: [mainUser, createdMemberUsers[0], createdMemberUsers[1], createdMemberUsers[2]],
      transactions: [
        {
          title: 'Sewa Villa Seminyak (3 Malam)',
          type: 'expense' as const,
          amount: '2500000',
          categoryName: 'Shopping',
          user: mainUser,
          note: 'DP awal villa beach view',
        },
        {
          title: 'Makan Malam Seafood Jimbaran',
          type: 'expense' as const,
          amount: '680000',
          categoryName: 'Food',
          user: createdMemberUsers[0],
          note: 'Makan bareng paket seafood',
        },
        {
          title: 'Sewa Mobil & Bensin 4 Hari',
          type: 'expense' as const,
          amount: '850000',
          categoryName: 'Transport',
          user: createdMemberUsers[1],
          note: 'Avanza Reborn plus driver',
        },
        {
          title: 'Patungan Kas Awal Bali',
          type: 'income' as const,
          amount: '4000000',
          categoryName: 'Bills',
          user: mainUser,
          note: 'Setoran dana dari anggota',
        },
      ],
      budget: {
        name: 'Anggaran Transport & Akomodasi',
        emojiIcon: '✈️',
        colorCode: '#00B4D8',
        limitAmount: '5000000',
      },
      savingsGoal: {
        name: 'Target Dana Darurat Bali',
        emojiIcon: '🎯',
        colorCode: '#00B4D8',
        targetAmount: '8000000',
        currentAmount: '5500000',
      },
    },
    {
      name: 'Kontrakan Ceria 🏡',
      emojiIcon: '🏡',
      colorCode: '#FFB703',
      description: 'Biaya operasional bulanan rumah kontrakan bersama',
      owner: mainUser,
      members: [mainUser, createdMemberUsers[3], createdMemberUsers[4]],
      transactions: [
        {
          title: 'Token Listrik PLN 500rb',
          type: 'expense' as const,
          amount: '501500',
          categoryName: 'Bills',
          user: mainUser,
          note: 'Token 500k via m-banking',
        },
        {
          title: 'WiFi Indihome 100Mbps',
          type: 'expense' as const,
          amount: '385000',
          categoryName: 'Bills',
          user: createdMemberUsers[3],
          note: 'Tagihan bulan Juli',
        },
        {
          title: 'Galon Aqua & Gas Elpiji 3kg',
          type: 'expense' as const,
          amount: '120000',
          categoryName: 'Food',
          user: createdMemberUsers[4],
          note: '4 galon + 2 gas',
        },
      ],
      budget: {
        name: 'Biaya Utility & Operational',
        emojiIcon: '💡',
        colorCode: '#FFB703',
        limitAmount: '1500000',
      },
      savingsGoal: {
        name: 'Dana Kas Perbaikan Kontrakan',
        emojiIcon: '🔨',
        colorCode: '#FFB703',
        targetAmount: '3000000',
        currentAmount: '1200000',
      },
    },
    {
      name: 'Project Kado Ultah 🎂',
      emojiIcon: '🎂',
      colorCode: '#E63946',
      description: 'Patungan kejutan ultah & kado smartwatch Budi',
      owner: createdMemberUsers[0],
      members: [createdMemberUsers[0], mainUser, createdMemberUsers[1]],
      transactions: [
        {
          title: 'Kue Ultah Custom Chocolate',
          type: 'expense' as const,
          amount: '350000',
          categoryName: 'Entertainment',
          user: createdMemberUsers[0],
          note: 'Pesan toko kue Harvest',
        },
        {
          title: 'Smartwatch Amazfit GTR 4',
          type: 'expense' as const,
          amount: '1850000',
          categoryName: 'Shopping',
          user: mainUser,
          note: 'Beli di Tokopedia Official',
        },
      ],
      budget: {
        name: 'Batas Budget Kado',
        emojiIcon: '🎁',
        colorCode: '#E63946',
        limitAmount: '2500000',
      },
      savingsGoal: {
        name: 'Patungan Kado Budi',
        emojiIcon: '⌚',
        colorCode: '#E63946',
        targetAmount: '2500000',
        currentAmount: '2200000',
      },
    },
  ];

  // 4. Seed each room
  for (const roomDef of roomDefinitions) {
    console.log(`\n🏠 Seeding room: "${roomDef.name}"...`);

    // Check if room already exists
    let room = await db.query.rooms.findFirst({
      where: (r, { and, eq }) =>
        and(eq(r.name, roomDef.name), eq(r.createdBy, roomDef.owner.id)),
    });

    if (!room) {
      const [newRoom] = await db
        .insert(schema.rooms)
        .values({
          name: roomDef.name,
          emojiIcon: roomDef.emojiIcon,
          colorCode: roomDef.colorCode,
          description: roomDef.description,
          createdBy: roomDef.owner.id,
        })
        .returning();
      room = newRoom;
      console.log(`   ✅ Room created with ID: ${room.id}`);
    } else {
      console.log(`   ⚠️ Room already exists with ID: ${room.id}`);
    }

    // Seed Room Members
    for (const memberUser of roomDef.members) {
      const isOwner = memberUser.id === roomDef.owner.id;
      const existingMember = await db.query.roomMembers.findFirst({
        where: (rm, { and, eq }) =>
          and(eq(rm.roomId, room.id), eq(rm.userId, memberUser.id)),
      });

      if (!existingMember) {
        await db.insert(schema.roomMembers).values({
          roomId: room.id,
          userId: memberUser.id,
          role: isOwner ? 'owner' : 'member',
        });
        console.log(`      ➕ Member added: ${memberUser.email} (${isOwner ? 'Owner' : 'Member'})`);
      }
    }

    // Seed Room Budget
    const existingBudget = await db.query.budgets.findFirst({
      where: (b, { eq }) => eq(b.roomId, room.id),
    });

    if (!existingBudget && roomDef.budget) {
      const now = new Date();
      const monthYear = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
      await db.insert(schema.budgets).values({
        userId: roomDef.owner.id,
        roomId: room.id,
        name: roomDef.budget.name,
        emojiIcon: roomDef.budget.emojiIcon,
        colorCode: roomDef.budget.colorCode,
        type: 'standalone',
        limitAmount: roomDef.budget.limitAmount,
        monthYear: monthYear,
      });
      console.log(`   ✅ Budget created: "${roomDef.budget.name}"`);
    }

    // Seed Room Savings Goal
    const existingGoal = await db.query.savingsGoals.findFirst({
      where: (sg, { eq }) => eq(sg.roomId, room.id),
    });

    let createdGoalId: string | null = null;
    if (!existingGoal && roomDef.savingsGoal) {
      const [sg] = await db
        .insert(schema.savingsGoals)
        .values({
          userId: roomDef.owner.id,
          roomId: room.id,
          name: roomDef.savingsGoal.name,
          emojiIcon: roomDef.savingsGoal.emojiIcon,
          colorCode: roomDef.savingsGoal.colorCode,
          targetAmount: roomDef.savingsGoal.targetAmount,
          currentAmount: roomDef.savingsGoal.currentAmount,
          status: 'in_progress',
        })
        .returning();
      createdGoalId = sg.id;
      console.log(`   ✅ Savings Goal created: "${roomDef.savingsGoal.name}"`);
    } else if (existingGoal) {
      createdGoalId = existingGoal.id;
    }

    // Seed Room Transactions
    for (const tx of roomDef.transactions) {
      const existingTx = await db.query.transactions.findFirst({
        where: (t, { and, eq }) =>
          and(eq(t.roomId, room.id), eq(t.title, tx.title)),
      });

      if (!existingTx) {
        // Find or create wallet for transaction user
        let userWallet = await db.query.wallets.findFirst({
          where: (w, { eq }) => eq(w.userId, tx.user.id),
        });

        if (!userWallet) {
          const [w] = await db
            .insert(schema.wallets)
            .values({
              userId: tx.user.id,
              name: 'Dompet Cash',
              emojiIcon: '💵',
              colorCode: '#6C63FF',
              type: 'cash',
              currency: 'IDR',
              isBaseCurrency: true,
              balance: '2000000',
            })
            .returning();
          userWallet = w;
        }

        const catId = categoryMap[tx.categoryName] || Object.values(categoryMap)[0];

        await db.insert(schema.transactions).values({
          userId: tx.user.id,
          walletId: userWallet.id,
          roomId: room.id,
          title: tx.title,
          type: tx.type,
          amount: tx.amount,
          baseAmount: tx.amount,
          categoryId: catId,
          savingsGoalId: createdGoalId,
          note: tx.note,
          date: new Date(),
        });
        console.log(`      💳 Transaction added: "${tx.title}" (Rp ${Number(tx.amount).toLocaleString('id-ID')})`);
      }
    }
  }

  console.log('\n🎉 Shared Rooms Seeding successfully completed!');
}

seedSharedRooms().catch((err) => {
  console.error('❌ Seeding failed with error:', err);
  process.exit(1);
});
