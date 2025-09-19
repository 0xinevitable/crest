import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { EnvConfig } from '@/common/env/schema';
import { envSchema } from '@/common/env/schema';

@Injectable()
export class EnvService {
  private _config?: EnvConfig;

  constructor(private readonly configService: ConfigService<EnvConfig, true>) {}

  get(): EnvConfig {
    if (this._config) {
      return this._config;
    }

    const keys = Object.keys(envSchema.shape) as (keyof EnvConfig)[];
    this._config = keys.reduce((config, key) => {
      config[key] = this.configService.get(key);
      return config;
    }, {} as EnvConfig);

    return this._config;
  }

  getKey<K extends keyof EnvConfig>(key: K): EnvConfig[K] {
    return this.configService.get(key);
  }

  has(key: keyof EnvConfig): boolean {
    return this.configService.get(key) !== undefined;
  }
}
