import micromatch from 'micromatch';
import createDebug from 'debug';

const debug = createDebug('lint-staged:config');

const shellScriptExtensions = [
	'*.sh',
	'*profile',
	'.bash_*',
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
	'mjs',
	'cjs',
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
	[`{${shellScriptExtensions.join(',')}}`]: 'shellcheck',
	'*': (files) => {
		// Ignore submodule files.
		debug('files', files);
		const matches = micromatch.not(files, ['submodules'], {
			contains: true,
		});

		debug('matches', matches);

		return debug.enabled || !matches.length
			? 'true'
			: `editorconfig-checker ${matches.join(' ')}`;
	},
};
