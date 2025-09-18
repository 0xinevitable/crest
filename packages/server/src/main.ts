import { NestFactory } from '@nestjs/core';
import { AppModule } from '@/app';
import { EnvService } from '@/common/env';

(async () => {
  const app = await NestFactory.create(AppModule);
  app.getHttpAdapter().getInstance().disable('x-powered-by');

  const { PORT } = app.get(EnvService).get();

  await app.listen(PORT);
})();
