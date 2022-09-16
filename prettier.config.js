/* eslint sort-keys: "error" */

/**
 * @type {import('prettier').Config}
 */
module.exports = {
	jsdocPreferCodeFences: true,
	jsdocSingleLineComment: false,
	jsdocVerticalAlignment: true,
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
	plugins: ['prettier-plugin-jsdoc', 'prettier-plugin-packagejson'],
	proseWrap: 'always',
	singleQuote: true,
	trailingComma: 'all',
	useTabs: true,
};
