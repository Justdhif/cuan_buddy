import { Injectable, Inject, NotFoundException, BadRequestException } from '@nestjs/common';
import { eq, and, or, ilike, ne } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { friendships, users, userProfiles } from '../database/schema';

@Injectable()
export class FriendshipsService {
  constructor(@Inject(DATABASE_CONNECTION) private readonly db: any) {}

  async sendRequest(senderId: string, usernameOrEmail: string) {
    // 1. Find user by email or username
    let targetUser = await this.db.query.users.findFirst({
      where: eq(users.email, usernameOrEmail),
      with: { profile: true },
    });

    if (!targetUser) {
      const profile = await this.db.query.userProfiles.findFirst({
        where: eq(userProfiles.username, usernameOrEmail),
      });
      if (profile) {
        targetUser = await this.db.query.users.findFirst({
          where: eq(users.id, profile.userId),
          with: { profile: true },
        });
      }
    }

    if (!targetUser) {
      throw new NotFoundException('User not found');
    }

    const receiverId = targetUser.id;

    if (senderId === receiverId) {
      throw new BadRequestException('Cannot send friend request to yourself');
    }

    // 2. Check if friendship already exists
    const existing = await this.db.query.friendships.findFirst({
      where: or(
        and(eq(friendships.senderId, senderId), eq(friendships.receiverId, receiverId)),
        and(eq(friendships.senderId, receiverId), eq(friendships.receiverId, senderId))
      ),
    });

    if (existing) {
      if (existing.status === 'accepted') {
        throw new BadRequestException('You are already friends with this user');
      }
      if (existing.status === 'pending') {
        if (existing.senderId === senderId) {
          throw new BadRequestException('Friend request already sent');
        } else {
          throw new BadRequestException('You have a pending friend request from this user');
        }
      }
      // If declined, reset to pending
      const [updated] = await this.db.update(friendships)
        .set({
          senderId,
          receiverId,
          status: 'pending',
          updatedAt: new Date(),
        })
        .where(eq(friendships.id, existing.id))
        .returning();
      return { message: 'Friend request sent successfully', friendship: updated };
    }

    // 3. Create new friendship request
    const [newFriendship] = await this.db.insert(friendships).values({
      senderId,
      receiverId,
      status: 'pending',
    }).returning();

    return { message: 'Friend request sent successfully', friendship: newFriendship };
  }

  async respondRequest(receiverId: string, friendshipId: string, action: 'accept' | 'decline') {
    const friendshipRecord = await this.db.query.friendships.findFirst({
      where: and(
        eq(friendships.id, friendshipId),
        eq(friendships.receiverId, receiverId),
        eq(friendships.status, 'pending')
      ),
    });

    if (!friendshipRecord) {
      throw new NotFoundException('Friend request not found or already processed');
    }

    const status = action === 'accept' ? 'accepted' : 'declined';
    const [updated] = await this.db.update(friendships)
      .set({
        status,
        updatedAt: new Date(),
      })
      .where(eq(friendships.id, friendshipId))
      .returning();

    return {
      message: `Friend request ${status === 'accepted' ? 'accepted' : 'declined'} successfully`,
      friendship: updated,
    };
  }

  async listFriends(userId: string) {
    const list = await this.db.query.friendships.findMany({
      where: and(
        or(eq(friendships.senderId, userId), eq(friendships.receiverId, userId)),
        eq(friendships.status, 'accepted')
      ),
    });

    const friends: any[] = [];
    for (const item of list) {
      const friendId = item.senderId === userId ? item.receiverId : item.senderId;
      const profile = await this.db.query.userProfiles.findFirst({
        where: eq(userProfiles.userId, friendId),
      });
      const user = await this.db.query.users.findFirst({
        where: eq(users.id, friendId),
      });

      friends.push({
        friendshipId: item.id,
        userId: friendId,
        email: user?.email,
        username: profile?.username || null,
        fullName: profile?.fullName || null,
        avatar: profile?.avatar || null,
      });
    }

    return friends;
  }

  async listPending(userId: string) {
    const list = await this.db.query.friendships.findMany({
      where: and(
        eq(friendships.receiverId, userId),
        eq(friendships.status, 'pending')
      ),
    });

    const requests: any[] = [];
    for (const item of list) {
      const profile = await this.db.query.userProfiles.findFirst({
        where: eq(userProfiles.userId, item.senderId),
      });
      const user = await this.db.query.users.findFirst({
        where: eq(users.id, item.senderId),
      });

      requests.push({
        friendshipId: item.id,
        senderId: item.senderId,
        email: user?.email,
        username: profile?.username || null,
        fullName: profile?.fullName || null,
        avatar: profile?.avatar || null,
        createdAt: item.createdAt,
      });
    }

    return requests;
  }

  async searchUsers(currentUserId: string, query: string) {
    if (!query || query.trim() === '') {
      return [];
    }

    // Search users by email or profile name
    const profiles = await this.db.query.userProfiles.findMany({
      where: and(
        ne(userProfiles.userId, currentUserId),
        or(
          ilike(userProfiles.username, `%${query}%`),
          ilike(userProfiles.fullName, `%${query}%`)
        )
      ),
      limit: 10,
    });

    const matchedUsers: any[] = [];
    
    // Add those matched by profile
    for (const p of profiles) {
      const user = await this.db.query.users.findFirst({
        where: eq(users.id, p.userId),
      });
      
      // Check friendship status if any
      const relation = await this.db.query.friendships.findFirst({
        where: or(
          and(eq(friendships.senderId, currentUserId), eq(friendships.receiverId, p.userId)),
          and(eq(friendships.senderId, p.userId), eq(friendships.receiverId, currentUserId))
        ),
      });

      matchedUsers.push({
        userId: p.userId,
        email: user?.email,
        username: p.username,
        fullName: p.fullName,
        avatar: p.avatar,
        friendshipStatus: relation ? relation.status : 'none',
        friendshipId: relation ? relation.id : null,
        isSender: relation ? relation.senderId === currentUserId : false,
      });
    }

    // Also search users by email directly if they don't match username/fullName but match email
    const usersByEmail = await this.db.query.users.findMany({
      where: and(
        ne(users.id, currentUserId),
        ilike(users.email, `%${query}%`)
      ),
      limit: 10,
    });

    for (const u of usersByEmail) {
      if (matchedUsers.some(m => m.userId === u.id)) continue;

      const profile = await this.db.query.userProfiles.findFirst({
        where: eq(userProfiles.userId, u.id),
      });

      const relation = await this.db.query.friendships.findFirst({
        where: or(
          and(eq(friendships.senderId, currentUserId), eq(friendships.receiverId, u.id)),
          and(eq(friendships.senderId, u.id), eq(friendships.receiverId, currentUserId))
        ),
      });

      matchedUsers.push({
        userId: u.id,
        email: u.email,
        username: profile?.username || null,
        fullName: profile?.fullName || null,
        avatar: profile?.avatar || null,
        friendshipStatus: relation ? relation.status : 'none',
        friendshipId: relation ? relation.id : null,
        isSender: relation ? relation.senderId === currentUserId : false,
      });
    }

    return matchedUsers;
  }
}
