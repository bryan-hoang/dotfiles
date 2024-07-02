import { spawnSync } from "node:child_process";
import { lstatSync } from "node:fs";
import createDebug from "debug";
import micromatch from "micromatch";

const debug = createDebug("lint-staged:config");

const shellScriptExtensions = [
	"*.sh",
	"*profile",
	".bash_*",
	"zshrc",
	"bashrc",
	"path",
	"exports",
	"functions",
	"aliases",
	"common",
	"xinitrc",
];

const spawnOutput = spawnSync(
	"sh",
	["-c", "git submodule status | awk '{print $2}'"],
	{
		stdio: "pipe",
		encoding: "utf-8",
	},
);

debug("spawnOutput", spawnOutput);
const submodules = spawnOutput.output[1]
	.split("\n")
	// Remove last empty string in array.
	.slice(0, -1);

debug("submodules", submodules);

/**
 * @param files {string[]}
 * @param command {string}
 * @returns {string[]} The filtered matches.
 */
function processMatches(files, command) {
	// Ignore submodule files.
	debug("files", files);
	const matches = micromatch
		.not(files, submodules, {
			contains: true,
		})
		.filter(
			(file) =>
				!lstatSync(file).isSymbolicLink() &&
				!file.match(/wind-term-settings\.json/),
		);

	debug("matches", matches);

	return debug.enabled || !matches.length
		? "true"
		: `${command} ${matches.join(" ")}`;
}

export default {
	"*": [
		(files) =>
			processMatches(
				files,
				"prettier --ignore-unknown --cache --cache-strategy=content --cache-location=.cache/prettier/cache --write",
			),
		"biome check --no-errors-on-unmatched --files-ignore-unknown=true --write --unsafe",
		(files) => processMatches(files, "editorconfig-checker"),
	],
	[`{${shellScriptExtensions.join(",")}}`]: (files) =>
		processMatches(files, "shellcheck"),
	"*.lua": (files) =>
		processMatches(files, "stylua --search-parent-directories"),
	"*.sh": (files) => processMatches(files, "shfmt -bn -ci --simplify"),
	"*.toml": (files) => processMatches(files, "taplo format"),
};
