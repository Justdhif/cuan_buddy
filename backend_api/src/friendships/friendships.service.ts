import { Injectable, Inject, NotFoundException, BadRequestException } from '@nestjs/common';
import { eq, and, or, ilike, ne, sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { friendships, users, userProfiles, notifications } from '../database/schema';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class FriendshipsService {
  constructor(
    @Inject(DATABASE_CONNECTION) private readonly db: any,
    private readonly notificationsService: NotificationsService
  ) {}

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

    // Get sender info for notification
    const senderProfile = await this.db.query.userProfiles.findFirst({
      where: eq(userProfiles.userId, senderId),
    });
    const senderUser = await this.db.query.users.findFirst({
      where: eq(users.id, senderId),
    });
    const senderName = senderProfile?.fullName || senderProfile?.username || senderUser?.email || 'Someone';

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

      void this.notificationsService.createAndBroadcast(
        receiverId,
        'FRIEND_REQUEST',
        JSON.stringify({
          friendshipId: updated.id,
          senderId,
          senderName,
          senderEmail: senderUser?.email,
        }),
        'friend_request'
      );

      return { message: 'Friend request sent successfully', friendship: updated };
    }

    // 3. Create new friendship request
    const [newFriendship] = await this.db.insert(friendships).values({
      senderId,
      receiverId,
      status: 'pending',
    }).returning();

    void this.notificationsService.createAndBroadcast(
      receiverId,
      'FRIEND_REQUEST',
      JSON.stringify({
        friendshipId: newFriendship.id,
        senderId,
        senderName,
        senderEmail: senderUser?.email,
      }),
      'friend_request'
    );

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

    // Send notification response back to the sender
    const receiverProfile = await this.db.query.userProfiles.findFirst({
      where: eq(userProfiles.userId, receiverId),
    });
    const receiverUser = await this.db.query.users.findFirst({
      where: eq(users.id, receiverId),
    });
    const receiverName = receiverProfile?.fullName || receiverProfile?.username || receiverUser?.email || 'Someone';

    void this.notificationsService.createAndBroadcast(
      friendshipRecord.senderId,
      status === 'accepted' ? 'FRIEND_REQUEST_ACCEPTED' : 'FRIEND_REQUEST_DECLINED',
      JSON.stringify({
        friendshipId: updated.id,
        receiverId,
        receiverName,
        receiverEmail: receiverUser?.email,
      }),
      status === 'accepted' ? 'friend_accepted' : 'friend_declined'
    );

    // Mark original friend request notification received by receiver (B) as read
    try {
      const notifList = await this.db.query.notifications.findMany({
        where: and(
          eq(notifications.userId, receiverId),
          eq(notifications.type, 'friend_request'),
          sql`message LIKE ${'%' + friendshipId + '%'}`
        )
      });
      for (const n of notifList) {
        await this.db.update(notifications)
          .set({ isRead: true })
          .where(eq(notifications.id, n.id));
      }
    } catch (e) {
      console.error('Failed to mark original request notification as read:', e);
    }

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
        avatarBorder: profile?.avatarBorder || null,
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
        avatarBorder: profile?.avatarBorder || null,
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
        avatarBorder: p.avatarBorder || null,
        friendshipStatus: relation ? relation.status : 'none',
        friendshipId: relation ? relation.id : null,
        isSender: relation ? relation.senderId === currentUserId : false,
      });
    }

    return matchedUsers;
  }
}
