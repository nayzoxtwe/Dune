import { Module } from '@nestjs/common';
import { AppController } from './controllers/app.controller';
import { RealtimeGateway } from './gateway/realtime.gateway';

@Module({
  imports: [],
  controllers: [AppController],
  providers: [RealtimeGateway]
})
export class AppModule {}
