/** @type {import('eslint').Linter.Config} */
module.exports = {
  root: true,
  extends: [
    'expo',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended',
    'plugin:@typescript-eslint/recommended-type-checked',
    'plugin:@typescript-eslint/stylistic-type-checked',
    'prettier',
  ],
  plugins: ['@typescript-eslint', 'react', 'react-hooks'],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaFeatures: { jsx: true },
    ecmaVersion: 'latest',
    sourceType: 'module',
    project: ['./tsconfig.eslint.json'],
    tsconfigRootDir: __dirname,
  },
  env: {
    es2021: true,
    node: true,
  },
  settings: {
    react: { version: 'detect' },
  },
  rules: {
    'prefer-const': 'error',

    // TypeScript handles this; use the TS-aware version instead
    'no-unused-vars': 'off',
    '@typescript-eslint/no-unused-vars': [
      'error',
      { argsIgnorePattern: '^_', varsIgnorePattern: '^_', caughtErrorsIgnorePattern: '^_' },
    ],

    // Keep RN components typed and intentional
    '@typescript-eslint/consistent-type-imports': ['error', { prefer: 'type-imports' }],

    // React 17+ JSX runtime
    'react/react-in-jsx-scope': 'off',
    'react/prop-types': 'off',
  },
  ignorePatterns: ['node_modules/', 'dist/', 'build/', '.expo/', '.expo-shared/'],
};
