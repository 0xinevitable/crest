import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { EnvService } from './service';
import { envSchema, EnvConfig } from './schema';

@Global()
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
      cache: true,
      validate: (config) => {
        const result = envSchema.safeParse(config);
        if (!result.success) {
          const errorMessages = result.error.issues.map((issue) => {
            const field = issue.path.length > 0 ? issue.path.join('.') : 'root';
            return `❌ ${field}: ${issue.message}`;
          });
          throw new Error(
            `🚨 Environment validation failed:\n\n${errorMessages.join('\n')}\n`,
          );
        }
        return result.data;
      },
    }),
  ],
  providers: [EnvService],
  exports: [EnvService],
})
class EnvModule {}

export { EnvModule, EnvService, type EnvConfig };
