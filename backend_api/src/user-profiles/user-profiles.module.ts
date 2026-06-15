import { Module } from '@nestjs/common';
import { UserProfilesController } from './user-profiles.controller';
import { UserProfilesService } from './user-profiles.service';

@Module({
  controllers: [UserProfilesController],
  providers: [UserProfilesService]
})
export class UserProfilesModule {}
