import { Body, Controller, Get, Post } from '@nestjs/common';

type RegisterDto = { email: string; password: string; role: 'adult' | 'teen' | 'parent' };

type FriendQrPayload = { uid: string; publicIdentityKey: string; displayName: string; checksum: string };

type MessageDto = { conversationId: string; ciphertext: string; type: 'text' | 'sticker' };

@Controller()
export class AppController {
  @Get('health')
  health() {
    return { status: 'ok' };
  }

  @Post('auth/register')
  register(@Body() dto: RegisterDto) {
    return { ...dto, id: 'user_' + dto.email };
  }

  @Post('friends/qr/issue')
  issueQr(@Body() payload: FriendQrPayload) {
    return { qr: Buffer.from(JSON.stringify(payload)).toString('base64url') };
  }

  @Post('messages')
  postMessage(@Body() dto: MessageDto) {
    return { accepted: true, envelope: dto };
  }
}
