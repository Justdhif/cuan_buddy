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

  async createRoom(userId: string, body: { name: string; memberUserIds?: string[]; emojiIcon?: string; colorCode?: string; description?: string; onlyOwnerCanInvite?: boolean }) {
    const { name, memberUserIds = [], emojiIcon, colorCode, description, onlyOwnerCanInvite = true } = body;
    if (!name || name.trim() === '') {
      throw new BadRequestException('Room name is required');
    }

    // 1. Create Room
    const [newRoom] = await this.db.insert(rooms).values({
      name,
      emojiIcon: emojiIcon || undefined,
      colorCode: colorCode || undefined,
      description: description || null,
      onlyOwnerCanInvite,
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
        avatarWings: profile?.avatarWings || null,
        bannerBorder: profile?.bannerBorder || null,
        bannerType: profile?.bannerType || 'color',
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
    // Verify current user is member
    const membership = await this.db.query.roomMembers.findFirst({
      where: and(eq(roomMembers.roomId, roomId), eq(roomMembers.userId, userId)),
    });

    if (!membership) {
      throw new ForbiddenException('You are not a member of this room');
    }

    // Check room's invite permission setting
    const roomRecord = await this.db.query.rooms.findFirst({
      where: eq(rooms.id, roomId),
    });

    if (roomRecord?.onlyOwnerCanInvite && membership.role !== 'owner') {
      throw new ForbiddenException('Only the room owner can invite members');
    }

    // Verify invitee is not already in the room
    const inviteeMembership = await this.db.query.roomMembers.findFirst({
      where: and(eq(roomMembers.roomId, roomId), eq(roomMembers.userId, inviteeId)),
    });

    if (inviteeMembership) {
      throw new BadRequestException('User is already a member of this room');
    }

    // Get room details (already fetched above if roomRecord exists)

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

  async updateRoom(userId: string, roomId: string, body: { name?: string; emojiIcon?: string; colorCode?: string; description?: string; onlyOwnerCanInvite?: boolean }) {
    // 1. Verify user is owner of the room
    const membership = await this.db.query.roomMembers.findFirst({
      where: and(eq(roomMembers.roomId, roomId), eq(roomMembers.userId, userId)),
    });

    if (!membership) {
      throw new ForbiddenException('You are not a member of this room');
    }

    if (membership.role !== 'owner') {
      throw new ForbiddenException('Only the owner can update room details');
    }

    const { name, emojiIcon, colorCode, description, onlyOwnerCanInvite } = body;

    const updateData: any = {};
    if (name !== undefined) updateData.name = name;
    if (emojiIcon !== undefined) updateData.emojiIcon = emojiIcon;
    if (colorCode !== undefined) updateData.colorCode = colorCode;
    if (description !== undefined) updateData.description = description;
    if (onlyOwnerCanInvite !== undefined) updateData.onlyOwnerCanInvite = onlyOwnerCanInvite;

    if (Object.keys(updateData).length === 0) {
      throw new BadRequestException('No fields to update');
    }

    const [updatedRoom] = await this.db.update(rooms)
      .set(updateData)
      .where(eq(rooms.id, roomId))
      .returning();

    return updatedRoom;
  }

  // ─── Invite Code: private helper ────────────────────────────────────────────
  private async _generateUniqueInviteCode(): Promise<string> {
    const CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no I,O,0,1 to avoid confusion
    const LENGTH = 8;
    let attempts = 0;
    while (attempts < 10) {
      let code = '';
      for (let i = 0; i < LENGTH; i++) {
        code += CHARS[Math.floor(Math.random() * CHARS.length)];
      }
      // Check uniqueness
      const existing = await this.db.query.rooms.findFirst({
        where: eq(rooms.inviteCode, code),
      });
      if (!existing) return code;
      attempts++;
    }
    throw new Error('Failed to generate unique invite code after 10 attempts');
  }

  // ─── Invite Code: generate / regenerate ─────────────────────────────────────
  async generateInviteCode(userId: string, roomId: string) {
    const membership = await this.db.query.roomMembers.findFirst({
      where: and(eq(roomMembers.roomId, roomId), eq(roomMembers.userId, userId)),
    });

    if (!membership) {
      throw new ForbiddenException('You are not a member of this room');
    }
    if (membership.role !== 'owner') {
      throw new ForbiddenException('Only the room owner can manage the invite code');
    }

    const newCode = await this._generateUniqueInviteCode();
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days from now

    const [updatedRoom] = await this.db.update(rooms)
      .set({ inviteCode: newCode, inviteCodeExpiresAt: expiresAt })
      .where(eq(rooms.id, roomId))
      .returning();

    return {
      inviteCode: updatedRoom.inviteCode,
      inviteCodeExpiresAt: updatedRoom.inviteCodeExpiresAt,
    };
  }

  // ─── Invite Code: delete (make room private again) ───────────────────────────
  async deleteInviteCode(userId: string, roomId: string) {
    const membership = await this.db.query.roomMembers.findFirst({
      where: and(eq(roomMembers.roomId, roomId), eq(roomMembers.userId, userId)),
    });

    if (!membership) {
      throw new ForbiddenException('You are not a member of this room');
    }
    if (membership.role !== 'owner') {
      throw new ForbiddenException('Only the room owner can manage the invite code');
    }

    await this.db.update(rooms)
      .set({ inviteCode: null, inviteCodeExpiresAt: null })
      .where(eq(rooms.id, roomId));

    return { message: 'Invite code deleted. Room is now private.' };
  }

  // ─── Join room via invite code ────────────────────────────────────────────────
  async joinRoomByInviteCode(userId: string, code: string) {
    const cleanCode = code.trim().toUpperCase().replace(/-/g, '');

    if (!cleanCode || cleanCode.length < 6) {
      throw new BadRequestException('Invalid invite code');
    }

    // Find room by invite code
    const room = await this.db.query.rooms.findFirst({
      where: eq(rooms.inviteCode, cleanCode),
    });

    if (!room) {
      throw new NotFoundException('Room not found. The invite code may be invalid.');
    }

    // Check expiry
    if (room.inviteCodeExpiresAt && new Date() > new Date(room.inviteCodeExpiresAt)) {
      throw new BadRequestException('This invite code has expired. Ask the room owner to generate a new one.');
    }

    // Check if user is already a member
    const existing = await this.db.query.roomMembers.findFirst({
      where: and(eq(roomMembers.roomId, room.id), eq(roomMembers.userId, userId)),
    });

    if (existing) {
      throw new BadRequestException('You are already a member of this room');
    }

    // Add user as member
    await this.db.insert(roomMembers).values({
      roomId: room.id,
      userId,
      role: 'member',
    });

    // Notify room owner
    const ownerMembership = await this.db.query.roomMembers.findFirst({
      where: and(eq(roomMembers.roomId, room.id), eq(roomMembers.role, 'owner')),
    });
    const joinerProfile = await this.db.query.userProfiles.findFirst({
      where: eq(userProfiles.userId, userId),
    });
    const joinerUser = await this.db.query.users.findFirst({
      where: eq(users.id, userId),
    });
    const joinerName = joinerProfile?.fullName || joinerProfile?.username || joinerUser?.email || 'Someone';

    if (ownerMembership) {
      void this.notificationsService.createAndBroadcast(
        ownerMembership.userId,
        'ROOM_JOIN',
        JSON.stringify({
          roomId: room.id,
          roomName: room.name,
          joinerId: userId,
          joinerName,
        }),
        'room_join'
      );
    }

    return { roomId: room.id, roomName: room.name };
  }
}
