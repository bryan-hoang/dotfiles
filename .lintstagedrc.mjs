import micromatch from 'micromatch';

const shellScriptExtensions = [
	'sh',
	'profile',
	'zprofile',
	'bash_profile',
	'zshrc',
	'bashrc',
	'path',
	'exports',
	'functions',
	'aliases',
	'common',
	'xinitrc',
];

const prettierExtensions = [
	'js',
	'jsx',
	'ts',
	'tsx',
	'json',
	'yml',
	'yaml',
	'css',
	'scss',
	'md',
	'mdx',
	'html',
	'xml',
];

export default {
	[`*.{${prettierExtensions.join(',')}}`]: 'prettier --write',
	[`*.{${shellScriptExtensions.join(',')}}`]: 'shellcheck',
	'*': (files) => {
		// Ignore submodule files.
		const matches = micromatch.not(files, ['**/submodules/**', '**/.asdf/**']);
		return `editorconfig-checker ${matches.join(' ')}`;
	},
};
