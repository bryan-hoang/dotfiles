import micromatch from 'micromatch';
import createDebug from 'debug';
import { spawnSync } from 'node:child_process';

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

const spawnOutput = spawnSync(
	'sh',
	['-c', "git submodule status | awk '{print $2}'"],
	{
		stdio: 'pipe',
		encoding: 'utf-8',
	},
);

debug('spawnOutput', spawnOutput);
const submodules = spawnOutput.output[1]
	.split('\n')
	// Remove last empty string in array.
	.slice(0, -1);

debug('submodules', submodules);

/**
 * @param files {string[]}
 * @param command {string}
 */
function processMatches(files, command) {
	// Ignore submodule files.
	debug('files', files);
	const matches = micromatch.not(files, submodules, {
		contains: true,
	});

	debug('matches', matches);

	return debug.enabled || !matches.length
		? 'true'
		: `${command} ${matches.join(' ')}`;
}

export default {
	[`*.{${prettierExtensions.join(',')}}`]: (files) =>
		processMatches(files, 'prettier --write'),
	[`{${shellScriptExtensions.join(',')}}`]: (files) =>
		processMatches(files, 'shellcheck'),
	'*': (files) => processMatches(files, 'editorconfig-checker'),
	'*.lua': (files) =>
		processMatches(files, 'stylua --search-parent-directories'),
	'*.sh': (files) => processMatches(files, 'shfmt -bn -ci --simplify'),
};
