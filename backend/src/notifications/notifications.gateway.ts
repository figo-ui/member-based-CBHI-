import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { AuthService } from '../auth/auth.service';

/**
 * Real-time notification gateway using Socket.IO.
 *
 * Clients connect with a Bearer token:
 *   socket = io('/notifications', { auth: { token: 'Bearer <accessToken>' } })
 *
 * Events emitted to clients:
 *   'notification'  — new in-app notification
 *   'claim_update'  — claim status changed
 *   'coverage_sync' — coverage renewed / activated
 */
@WebSocketGateway({
  namespace: '/notifications',
  cors: {
    origin: (process.env.CORS_ALLOWED_ORIGINS ?? '*').split(',').map((o: string) => o.trim()),
    credentials: true,
  },
})
export class NotificationsGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(NotificationsGateway.name);

  // userId → Set of socket IDs
  private readonly userSockets = new Map<string, Set<string>>();

  constructor(private readonly authService: AuthService) {}

  async handleConnection(client: Socket) {
    try {
      const token =
        (client.handshake.auth as Record<string, string>)?.token ??
        client.handshake.headers.authorization;

      if (!token) {
        client.disconnect(true);
        return;
      }

      const user = await this.authService.requireUserFromAuthorization(token);
      (client as Socket & { userId: string }).userId = user.id;

      // Join a room named after the user ID for targeted delivery
      await client.join(`user:${user.id}`);

      if (!this.userSockets.has(user.id)) {
        this.userSockets.set(user.id, new Set());
      }
      this.userSockets.get(user.id)!.add(client.id);

      this.logger.log(`WS connected: user=${user.id} socket=${client.id}`);
    } catch {
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket) {
    const userId = (client as Socket & { userId?: string }).userId;
    if (userId) {
      this.userSockets.get(userId)?.delete(client.id);
      if (this.userSockets.get(userId)?.size === 0) {
        this.userSockets.delete(userId);
      }
    }
    this.logger.log(`WS disconnected: socket=${client.id}`);
  }

  /** Push a notification to a specific user (all their connected devices) */
  pushToUser(
    userId: string,
    event: string,
    payload: Record<string, unknown>,
  ) {
    this.server.to(`user:${userId}`).emit(event, payload);
  }

  /** Push a notification object to a user */
  pushNotification(userId: string, notification: {
    id: string;
    type: string;
    title: string;
    message: string;
    payload?: Record<string, unknown> | null;
    createdAt: string;
  }) {
    this.pushToUser(userId, 'notification', notification);
  }

  /** Broadcast claim status update to the household head and beneficiary */
  pushClaimUpdate(userIds: string[], claimSummary: Record<string, unknown>) {
    for (const userId of userIds) {
      this.pushToUser(userId, 'claim_update', claimSummary);
    }
  }

  /** Broadcast coverage activation (after payment webhook) */
  pushCoverageSync(userId: string, coverageSummary: Record<string, unknown>) {
    this.pushToUser(userId, 'coverage_sync', coverageSummary);
  }

  @SubscribeMessage('ping')
  handlePing(@ConnectedSocket() client: Socket, @MessageBody() _data: unknown) {
    client.emit('pong', { ts: Date.now() });
  }
}
