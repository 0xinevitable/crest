import { defineConfig } from '@wagmi/cli';
import { foundry } from '@wagmi/cli/plugins';

export default defineConfig({
  out: 'typescript/generated.ts',
  plugins: [
    foundry({
      project: '.',
      exclude: ['script', 'test'],
    }),
  ],
});
