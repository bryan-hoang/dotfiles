/**
 * @type {import('prettier').Config}
 */
export default {
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
		{
			files: 'gemrc',
			options: {
				parser: 'yaml',
			},
		},
	],
	plugins: ['prettier-plugin-packagejson'],
	proseWrap: 'always',
	singleQuote: true,
	trailingComma: 'all',
	useTabs: true,
};
