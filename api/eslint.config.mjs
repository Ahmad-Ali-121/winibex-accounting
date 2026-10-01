import js from '@eslint/js';

export default [
  {
    ignores: ['node_modules/**', 'coverage/**', 'uploads/**'],
  },
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 2024,
      sourceType: 'module',
      globals: {
        process: 'readonly',
        console: 'readonly',
        Buffer: 'readonly',
        URL: 'readonly',
        URLSearchParams: 'readonly',
        setTimeout: 'readonly',
        clearTimeout: 'readonly',
        setInterval: 'readonly',
        clearInterval: 'readonly',
        structuredClone: 'readonly',
        fetch: 'readonly',
        crypto: 'readonly',
      },
    },
    rules: {
      eqeqeq: ['error', 'always', { null: 'ignore' }],
      'no-unused-vars': ['error', { argsIgnorePattern: '^_', caughtErrors: 'all' }],
      'no-var': 'error',
      'prefer-const': 'error',
      'no-return-await': 'error',
      'require-await': 'error',
      'no-throw-literal': 'error',

      // Money is integer paisa everywhere. These catch the two easiest ways to
      // turn it back into something that drifts.
      'no-loss-of-precision': 'error',
      'no-restricted-properties': [
        'error',
        { object: 'Math', property: 'round', message: 'Money is integer paisa. Round at display only.' },
      ],
      'no-restricted-globals': [
        'error',
        { name: 'parseFloat', message: 'Money is integer paisa. Never parse it as a float.' },
      ],
    },
  },
];
