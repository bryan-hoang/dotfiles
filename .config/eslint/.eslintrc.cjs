/**
 * @type {import('eslint').Linter.Config}
 */
module.exports = {
	env: {
		es2022: true,
		node: true,
		browser: true,
		worker: true,
	},
	extends: [
		'eslint:recommended',
		'plugin:node/recommended',
		'plugin:security/recommended',
		'plugin:jsdoc/recommended-typescript',
		'plugin:markdown/recommended',
		'airbnb-base',
		'plugin:prettier/recommended',
	],
	ignorePatterns: ['!.*'],
	overrides: [
		{
			files: ['**/*.md'],
			processor: 'markdown/markdown',
		},
		{
			files: ['**/*.md/*.js'],
			rules: {
				'global-require': 'off',
				'import/no-unresolved': 'off',
				'no-console': 'off',
				'no-undef': 'off',
				'no-unused-vars': 'off',
				'node/no-missing-require': 'off',
			},
		},
		{
			files: ['*.ts'],
			extends: [
				'plugin:@typescript-eslint/recommended',
				'plugin:@typescript-eslint/recommended-requiring-type-checking',
				'airbnb-typescript/base',
			],
			parserOptions: {
				project: '/home/bryan/tsconfig.json',
			},
		},
	],
	parser: '@typescript-eslint/parser',
	parserOptions: {
		ecmaFeatures: {
			globalReturn: true,
		},
		sourceType: 'module',
		ecmaVersion: 'latest',
	},
	plugins: ['security', 'jsdoc', 'markdown', '@typescript-eslint', 'html'],
	root: true,
	rules: {
		'jsdoc/require-jsdoc': [
			'warn',
			{
				publicOnly: true,
			},
		],
		'jsdoc/require-file-overview': 'warn',
		'no-unused-vars': [
			'error',
			{
				argsIgnorePattern: '^_',
				destructuredArrayIgnorePattern: '^_',
			},
		],
		'@typescript-eslint/dot-notation': 'off',
		'node/no-unsupported-features/node-builtins': [
			'error',
			{
				version: '>=14.0.0',
			},
		],
	},
	settings: {
		jsdoc: {
			mode: 'typescript',
		},
	},
};