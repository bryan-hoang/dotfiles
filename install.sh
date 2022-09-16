#!/usr/bin/env bash
set -euo pipefail

dot() {
	git --git-dir="${HOME}"/.git --work-tree="${HOME}" "${@}"
}

clone_repo() {
	local -r REPOSITORY_HOST=github.com
	local -r REPOSITORY=git@${REPOSITORY_HOST}:bryan-hoang/dotfiles.git

	if ! grep -q "^${REPOSITORY_HOST} " "${HOME}"/.ssh/known_hosts; then
		touch "${HOME}"/.ssh/known_hosts
		ssh-keyscan "${REPOSITORY_HOST}" >>"${HOME}"/.ssh/known_hosts 2>/dev/null
	fi

	dot init
	dot remote add origin "${REPOSITORY}"
	dot fetch
	dot switch -t origin/main
	dot submodule update --init --recursive
}

if [ ! -d "${HOME}"/.git ] || [ ! -f "${HOME}"/.functions ]; then
	clone_repo
fi

# shellcheck source=.functions
. "${HOME}"/.functions

if [ ! -f "${HOME}"/submodules/.tmux/.tmux.conf ]; then
	ln -s -f "${HOME}"/submodules/.tmux/.tmux.conf "${HOME}"
fi

declare -a programs=(
	curl
	keychain
	brew
	gh
	wget
	starship
	cht.sh
	pandoc
	shellcheck
	rustc
	unzip
	deno
	pnpm
	check_if_email_exists
	dotenv-linter
	vale
	lua-language-server
	pinentry-tty
)

if has_sudo; then
	programs+=(
		flatpak
		nvim
		jq
		rustdesk
		poetry
	)
fi

for program in "${programs[@]}"; do
	if ! does_program_exist "${program}"; then
		install_"${program}"
	fi
done

if ! is_git_bash; then
	declare -ar asdf_plugins=(direnv nodejs golang python)

	for asdf_plugin in "${asdf_plugins[@]}"; do
		if ! is_asdf_plugin_installed "${asdf_plugin}"; then
			install_asdf_plugin "${asdf_plugin}"
		fi
	done
fi

readonly -a vale_styles=(
	Google
	Microsoft
	IBM
	write-good
	proselint
	alex
	Readability
	Openly
)

mkdir -p "${HOME}"/styles
for style in "${vale_styles[@]}"; do
	cp -rf "${HOME}"/submodules/"${style}"/"${style}" "${HOME}"/styles
done

if is_wsl && [[ ! -f /etc/wsl.conf ]]; then
	wget -qO- https://gist.githubusercontent.com/bryan-hoang/30d4fd5d764977b01bf3de63681392b6/raw/5c2fce70efc43364099005765b2c83e4ee2c7c60/wsl.conf \
		| sudo tee /etc/wsl.conf >/dev/null
fi

link_zsh_plugins
link_bash_plugins
link_nvim_custom_config

echo "Finished installing Bryan's dotfiles setup!"
git fetch origin && git reset --hard "$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}')" && git clean -fd
