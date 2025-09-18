import { Controller, Get, Module } from '@nestjs/common';
import { APP_FILTER, APP_INTERCEPTOR } from '@nestjs/core';

import { HttpLoggingInterceptor } from '@/shared/interceptor/http-logging';
import { AllExceptionsFilter } from '@/shared/filter/all-exceptions';

import { TasksModule } from '@/domain/tasks';

@Controller('/')
class HealthCheckController {
  @Get()
  healthcheck(): string {
    return 'ok';
  }
}

@Module({
  imports: [TasksModule],
  controllers: [HealthCheckController],
  providers: [
    {
      provide: APP_INTERCEPTOR,
      useClass: HttpLoggingInterceptor,
    },
    {
      provide: APP_FILTER,
      useClass: AllExceptionsFilter,
    },
  ],
})
export class AppModule {}
