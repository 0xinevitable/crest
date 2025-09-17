module.exports = {
  bracketSpacing: true,
  jsxBracketSameLine: false,
  singleQuote: true,
  trailingComma: 'all',
  semi: true,

  plugins: [
    'prettier-plugin-solidity',
    '@trivago/prettier-plugin-sort-imports',
  ],

  overrides: [
    {
      files: '*.sol',
      options: {
        tabWidth: 4,
      },
    },
  ],
  importOrder: ['<THIRD_PARTY_MODULES>', '@/(.*)$', '^[./](.*)$'],
  importOrderSeparation: true,
  importOrderSortSpecifiers: true,
};
