import { Injectable, Inject, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { eq, and, inArray, sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { rooms, roomMembers, users, userProfiles, transactions, budgets, savingsGoals } from '../database/schema';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class RoomsService {
  constructor(
    @Inject(DATABASE_CONNECTION) private readonly db: any,
    private readonly notificationsService: NotificationsService
  ) {}

  async createRoom(userId: string, body: { name: string; memberUserIds?: string[]; emojiIcon?: string; colorCode?: string; description?: string }) {
    const { name, memberUserIds = [], emojiIcon, colorCode, description } = body;
    if (!name || name.trim() === '') {
      throw new BadRequestException('Room name is required');
    }

    // 1. Create Room
    const [newRoom] = await this.db.insert(rooms).values({
      name,
      emojiIcon: emojiIcon || undefined,
      colorCode: colorCode || undefined,
      description: description || null,
      createdBy: userId,
    }).returning();

    // 2. Add creator as Owner
    await this.db.insert(roomMembers).values({
      roomId: newRoom.id,
      userId: userId,
      role: 'owner',
    });

    // 3. Add members
    if (memberUserIds.length > 0) {
      const valuesToInsert = memberUserIds.map((mId) => ({
        roomId: newRoom.id,
        userId: mId,
        role: 'member',
      }));
      await this.db.insert(roomMembers).values(valuesToInsert);

      // Send notification to invited members
      const creatorProfile = await this.db.query.userProfiles.findFirst({
        where: eq(userProfiles.userId, userId),
      });
      const creatorUser = await this.db.query.users.findFirst({
        where: eq(users.id, userId),
      });
      const creatorName = creatorProfile?.fullName || creatorProfile?.username || creatorUser?.email || 'Someone';

      for (const mId of memberUserIds) {
        void this.notificationsService.createAndBroadcast(
          mId,
          'ROOM_INVITATION',
          JSON.stringify({
            roomId: newRoom.id,
            roomName: newRoom.name,
            inviterId: userId,
            inviterName: creatorName,
          }),
          'room_invite'
        );
      }
    }

    return newRoom;
  }

  async listRooms(userId: string) {
    // Find all room ids where user is a member
    const memberships = await this.db.query.roomMembers.findMany({
      where: eq(roomMembers.userId, userId),
    });

    if (memberships.length === 0) {
      return [];
    }

    const roomIds = memberships.map((m) => m.roomId);

    // Get rooms details
    const roomsList = await this.db.query.rooms.findMany({
      where: inArray(rooms.id, roomIds),
    });

    const result: any[] = [];
    for (const r of roomsList) {
      const membersCount = await this.db.select({ count: sql`count(*)` })
        .from(roomMembers)
        .where(eq(roomMembers.roomId, r.id));
      
      const role = memberships.find((m) => m.roomId === r.id)?.role;

      result.push({
        ...r,
        role,
        membersCount: Number(membersCount[0].count),
      });
    }

    return result;
  }

  async getRoomDetail(userId: string, roomId: string) {
    // Verify membership
    const membership = await this.db.query.roomMembers.findFirst({
      where: and(eq(roomMembers.roomId, roomId), eq(roomMembers.userId, userId)),
    });

    if (!membership) {
      throw new ForbiddenException('You are not a member of this room');
    }

    const room = await this.db.query.rooms.findFirst({
      where: eq(rooms.id, roomId),
    });

    if (!room) {
      throw new NotFoundException('Room not found');
    }

    // Get members details
    const membersList = await this.db.query.roomMembers.findMany({
      where: eq(roomMembers.roomId, roomId),
    });

    const members: any[] = [];
    for (const m of membersList) {
      const profile = await this.db.query.userProfiles.findFirst({
        where: eq(userProfiles.userId, m.userId),
      });
      const u = await this.db.query.users.findFirst({
        where: eq(users.id, m.userId),
      });

      members.push({
        userId: m.userId,
        role: m.role,
        email: u?.email,
        username: profile?.username || null,
        fullName: profile?.fullName || null,
        avatar: profile?.avatar || null,
        avatarBorder: profile?.avatarBorder || null,
      });
    }

    // Calculate aggregated statistics for this room
    // 1. Transactions Total (Income & Expense)
    const roomTransactions = await this.db.query.transactions.findMany({
      where: eq(transactions.roomId, roomId),
    });

    let totalIncome = 0;
    let totalExpense = 0;

    for (const tx of roomTransactions) {
      const amount = Number(tx.baseAmount || tx.amount);
      if (tx.type === 'income') {
        totalIncome += amount;
      } else {
        totalExpense += amount;
      }
    }

    // 2. Budgets
    const roomBudgets = await this.db.query.budgets.findMany({
      where: eq(budgets.roomId, roomId),
    });

    // 3. Savings Goals
    const roomSavings = await this.db.query.savingsGoals.findMany({
      where: eq(savingsGoals.roomId, roomId),
    });

    return {
      ...room,
      role: membership.role,
      members,
      summary: {
        totalIncome,
        totalExpense,
        balance: totalIncome - totalExpense,
        transactionsCount: roomTransactions.length,
        budgetsCount: roomBudgets.length,
        savingsGoalsCount: roomSavings.length,
      },
    };
  }

  async leaveOrDeleteRoom(userId: string, roomId: string) {
    const membership = await this.db.query.roomMembers.findFirst({
      where: and(eq(roomMembers.roomId, roomId), eq(roomMembers.userId, userId)),
    });

    if (!membership) {
      throw new ForbiddenException('You are not a member of this room');
    }

    if (membership.role === 'owner') {
      // Owner deletes the room
      await this.db.delete(rooms).where(eq(rooms.id, roomId));
      return { message: 'Room and all associated data deleted successfully' };
    } else {
      // Member leaves the room
      await this.db.delete(roomMembers).where(and(eq(roomMembers.roomId, roomId), eq(roomMembers.userId, userId)));
      return { message: 'You have left the room' };
    }
  }

  async inviteMember(userId: string, roomId: string, inviteeId: string) {
    // Verify current user is member (preferably owner)
    const membership = await this.db.query.roomMembers.findFirst({
      where: and(eq(roomMembers.roomId, roomId), eq(roomMembers.userId, userId)),
    });

    if (!membership) {
      throw new ForbiddenException('You are not a member of this room');
    }

    // Verify invitee is not already in the room
    const inviteeMembership = await this.db.query.roomMembers.findFirst({
      where: and(eq(roomMembers.roomId, roomId), eq(roomMembers.userId, inviteeId)),
    });

    if (inviteeMembership) {
      throw new BadRequestException('User is already a member of this room');
    }

    // Get room details
    const roomRecord = await this.db.query.rooms.findFirst({
      where: eq(rooms.id, roomId),
    });

    // Get inviter details
    const inviterProfile = await this.db.query.userProfiles.findFirst({
      where: eq(userProfiles.userId, userId),
    });
    const inviterUser = await this.db.query.users.findFirst({
      where: eq(users.id, userId),
    });
    const inviterName = inviterProfile?.fullName || inviterProfile?.username || inviterUser?.email || 'Someone';

    // Add member
    const [newMember] = await this.db.insert(roomMembers).values({
      roomId,
      userId: inviteeId,
      role: 'member',
    }).returning();

    // Send notification to invitee
    void this.notificationsService.createAndBroadcast(
      inviteeId,
      'ROOM_INVITATION',
      JSON.stringify({
        roomId,
        roomName: roomRecord?.name || 'Room',
        inviterId: userId,
        inviterName,
      }),
      'room_invite'
    );

    return newMember;
  }
}
