import { Logger } from '@nestjs/common';
import { OnGatewayConnection, SubscribeMessage, WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

type TypingPayload = { conversationId: string; authorId: string };

type PresencePayload = { userId: string; status: 'online' | 'away' | 'offline' };

@WebSocketGateway({ cors: { origin: '*' } })
export class RealtimeGateway implements OnGatewayConnection {
  private readonly logger = new Logger('RealtimeGateway');

  @WebSocketServer()
  server!: Server;

  handleConnection(client: Socket) {
    this.logger.log(`Client connected ${client.id}`);
  }

  @SubscribeMessage('typing')
  handleTyping(client: Socket, payload: TypingPayload) {
    client.to(payload.conversationId).emit('typing', payload);
  }

  @SubscribeMessage('presence:update')
  handlePresence(_: Socket, payload: PresencePayload) {
    this.server.emit('presence:update', payload);
  }
}
