/**
 * @type {import('prettier').Config}
 */
export default {
	overrides: [
		{
			files: "*.keystore",
			options: {
				parser: "json",
			},
		},
		{
			files: "*.css",
			options: {
				singleQuote: false,
			},
		},
		{
			files: "gemrc",
			options: {
				parser: "yaml",
			},
		},
		{
			files: "*.svg",
			options: {
				parser: "html",
			},
		},
	],
	plugins: ["prettier-plugin-packagejson"],
	proseWrap: "always",
	useTabs: true,
};
