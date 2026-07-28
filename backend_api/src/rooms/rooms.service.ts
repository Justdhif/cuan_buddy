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

    const [newRoom] = await this.db.insert(rooms).values({
      name,
      emojiIcon: emojiIcon || undefined,
      colorCode: colorCode || undefined,
      description: description || null,
      onlyOwnerCanInvite,
      createdBy: userId,
    }).returning();

    await this.db.insert(roomMembers).values({
      roomId: newRoom.id,
      userId: userId,
      role: 'owner',
    });

    if (memberUserIds.length > 0) {
      const valuesToInsert = memberUserIds.map((mId) => ({
        roomId: newRoom.id,
        userId: mId,
        role: 'member',
      }));
      await this.db.insert(roomMembers).values(valuesToInsert);

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

    const memberships = await this.db.query.roomMembers.findMany({
      where: eq(roomMembers.userId, userId),
    });

    if (memberships.length === 0) {
      return [];
    }

    const roomIds = memberships.map((m) => m.roomId);

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

    const roomBudgets = await this.db.query.budgets.findMany({
      where: eq(budgets.roomId, roomId),
    });

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

      await this.db.delete(rooms).where(eq(rooms.id, roomId));
      return { message: 'Room and all associated data deleted successfully' };
    } else {

      await this.db.delete(roomMembers).where(and(eq(roomMembers.roomId, roomId), eq(roomMembers.userId, userId)));
      return { message: 'You have left the room' };
    }
  }

  async inviteMember(userId: string, roomId: string, inviteeId: string) {

    const membership = await this.db.query.roomMembers.findFirst({
      where: and(eq(roomMembers.roomId, roomId), eq(roomMembers.userId, userId)),
    });

    if (!membership) {
      throw new ForbiddenException('You are not a member of this room');
    }

    const roomRecord = await this.db.query.rooms.findFirst({
      where: eq(rooms.id, roomId),
    });

    if (roomRecord?.onlyOwnerCanInvite && membership.role !== 'owner') {
      throw new ForbiddenException('Only the room owner can invite members');
    }

    const inviteeMembership = await this.db.query.roomMembers.findFirst({
      where: and(eq(roomMembers.roomId, roomId), eq(roomMembers.userId, inviteeId)),
    });

    if (inviteeMembership) {
      throw new BadRequestException('User is already a member of this room');
    }

    const inviterProfile = await this.db.query.userProfiles.findFirst({
      where: eq(userProfiles.userId, userId),
    });
    const inviterUser = await this.db.query.users.findFirst({
      where: eq(users.id, userId),
    });
    const inviterName = inviterProfile?.fullName || inviterProfile?.username || inviterUser?.email || 'Someone';

    const [newMember] = await this.db.insert(roomMembers).values({
      roomId,
      userId: inviteeId,
      role: 'member',
    }).returning();

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

  private async _generateUniqueInviteCode(): Promise<string> {
    const CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    const LENGTH = 8;
    let attempts = 0;
    while (attempts < 10) {
      let code = '';
      for (let i = 0; i < LENGTH; i++) {
        code += CHARS[Math.floor(Math.random() * CHARS.length)];
      }

      const existing = await this.db.query.rooms.findFirst({
        where: eq(rooms.inviteCode, code),
      });
      if (!existing) return code;
      attempts++;
    }
    throw new Error('Failed to generate unique invite code after 10 attempts');
  }

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
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    const [updatedRoom] = await this.db.update(rooms)
      .set({ inviteCode: newCode, inviteCodeExpiresAt: expiresAt })
      .where(eq(rooms.id, roomId))
      .returning();

    return {
      inviteCode: updatedRoom.inviteCode,
      inviteCodeExpiresAt: updatedRoom.inviteCodeExpiresAt,
    };
  }

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

  async joinRoomByInviteCode(userId: string, code: string) {
    const cleanCode = code.trim().toUpperCase().replace(/-/g, '');

    if (!cleanCode || cleanCode.length < 6) {
      throw new BadRequestException('Invalid invite code');
    }

    const room = await this.db.query.rooms.findFirst({
      where: eq(rooms.inviteCode, cleanCode),
    });

    if (!room) {
      throw new NotFoundException('Room not found. The invite code may be invalid.');
    }

    if (room.inviteCodeExpiresAt && new Date() > new Date(room.inviteCodeExpiresAt)) {
      throw new BadRequestException('This invite code has expired. Ask the room owner to generate a new one.');
    }

    const existing = await this.db.query.roomMembers.findFirst({
      where: and(eq(roomMembers.roomId, room.id), eq(roomMembers.userId, userId)),
    });

    if (existing) {
      throw new BadRequestException('You are already a member of this room');
    }

    await this.db.insert(roomMembers).values({
      roomId: room.id,
      userId,
      role: 'member',
    });

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
