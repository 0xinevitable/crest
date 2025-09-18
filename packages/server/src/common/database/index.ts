import { Global, Module } from '@nestjs/common';
import { DiscoveryModule } from '@nestjs/core';

import { DatabaseService } from './service';

@Global()
@Module({
  imports: [DiscoveryModule],
  providers: [DatabaseService],
  exports: [DatabaseService],
})
class DatabaseModule {}

export { DatabaseModule, DatabaseService };
