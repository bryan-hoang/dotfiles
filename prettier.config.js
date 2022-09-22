/* eslint sort-keys: "error" */

/**
 * @type {import('prettier').Config}
 */
module.exports = {
	overrides: [
		{
			files: '*.keystore',
			options: {
				parser: 'json',
			},
		},
		{
			files: '*.css',
			options: {
				singleQuote: false,
			},
		},
	],
	plugins: ['prettier-plugin-packagejson'],
	printWidth: 80,
	proseWrap: 'always',
	singleQuote: true,
	trailingComma: 'all',
	useTabs: true,
};
