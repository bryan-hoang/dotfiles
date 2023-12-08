// https://commitlint.js.org/#/reference-configuration

import type { UserConfig } from '@commitlint/types';

export default {
	extends: ['@commitlint/config-conventional'],
	rules: {
		'header-max-length': [2, 'always', 50],
		'body-max-line-length': [1, 'always', 72],
		'footer-max-line-length': [1, 'always', 72],
		'signed-off-by': [1, 'always', 'Reviewed-by'],
		'trailer-exists': [1, 'always', 'Refs'],
	},
} satisfies UserConfig;
