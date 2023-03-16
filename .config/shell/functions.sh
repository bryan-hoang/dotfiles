#!/usr/bin/env bash
#
# shellcheck disable=2154

# https://github.com/anordal/shellharden/blob/master/how_to_do_things_safely_in_bash.md#assert-that-command-dependencies-are-installed
require() {
	hash "$@" || return 127
}

# https://github.com/anordal/shellharden/blob/master/how_to_do_things_safely_in_bash.md#echo--printf
println() {
	printf '%s\n' "$*"
}

# region Installation

DOWNLOAD_DIR="$HOME"/Downloads
FONT_DIR="$XDG_DATA_HOME"/fonts
DEFAULT_PKGS_DIR="$XDG_CONFIG_HOME"/default-pkgs

install_gh() {
	echo "Installing gh..."
	if is_git_bash; then
		winget install GitHub.cli
		echo "You may need to reload your shell for your path to update with the new program."
	elif does_command_exist brew; then
		brew install gh
	elif is_arm64_architecture; then
		curl -s https://api.github.com/repos/cli/cli/releases/latest \
			| grep "browser_download_url.*deb" \
			| cut -d : -f 2,3 \
			| tr -d \" \
			| wget -P "$DOWNLOAD_DIR" -qi -
		sudo apt install "$DOWNLOAD_DIR"/gh_*_linux_arm64.deb
	fi

	gh --version
	if ! gh auth status; then
		gh auth login --web
	fi
	echo "Installed gh successfully!"
}

install_wget() {
	echo "Installing wget..."
	if is_git_bash; then
		gh release download -R webfolderio/wget-windows -p 'wget-*-64bit-OpenSSL.zip' -D "$DOWNLOAD_DIR"
		unzip "${HOME}/Downloads/wget-*-64bit-OpenSSL.zip" -d "$DOWNLOAD_DIR"
		mv "${HOME}/Downloads/wget.exe" "$XDG_BIN_HOME"
	fi
	wget --version
	echo "Installed wget successfully!"
}

install_git() {
	require gh jq
	install_apt_packages libcurl4-openssl-dev
	echo "Installing git..."
	local -r TARBALL_URL="$(gh api repos/git/git/tags \
		| jq --raw-output '.[0].tarball_url')"
	wget "$TARBALL_URL" -O "$SRC_DIR"/git.tar.gz || return 1
	tar -xf "$SRC_DIR"/git.tar.gz -C "$SRC_DIR"
	cd "$SRC_DIR"/git-* || return 1
	make prefix="$XDG_LOCAL_HOME" all
	make prefix="$XDG_LOCAL_HOME" install
	git --version
	cd - || return 1
	echo "Installed git successfully!"
}

install_git_lfs() {
	echo "Installing git-lfs..."
	if is_debian_os; then
		curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh \
			| sudo bash
		sudo apt-get install git-lfs
		git lfs install
	fi
	echo "Installed git-lfs successfully!"
}

install_starship() {
	echo "Installing starship..."
	mkdir -p "$XDG_BIN_HOME"
	curl -sS https://starship.rs/install.sh \
		| sh -s -- -b "$XDG_BIN_HOME" -y >/dev/null
	starship --version
	echo "Installed starship successfully!"
}

install_unzip() {
	echo "Installing unzip..."
	install_apt_packages unzip
	unzip --version
	echo "Installed unzip successfully!"
}

install_deno() {
	if ! is_arm32_architecture && ! is_arm64_architecture; then
		require unzip || return
		echo "Installing deno..."
		curl -fsSL https://deno.land/x/install/install.sh \
			| sh >/dev/null
		deno --version
		echo "Installed deno successfully!"
	fi
}

install_pandoc() {
	if ! is_arm32_architecture; then
		if has_sudo; then
			echo "Installing pandoc..."
			gh release download -R jgm/pandoc -p 'pandoc-*-*.deb' -D "$DOWNLOAD_DIR"

			local arch_tag
			if is_arm64_architecture; then
				arch_tag='arm64'
			else
				arch_tag='amd64'
			fi

			sudo apt install "$DOWNLOAD_DIR"/pandoc*"$arch_tag".deb

			pandoc --version
			echo "Installed pandoc successfully!"
		elif is_git_bash; then
			echo "Installing pandoc..."
			winget install JohnMacFarlane.Pandoc
			echo "You may need to reload your shell for your path to update with the new program."

			pandoc --version
			echo "Installed pandoc successfully!"
		fi
	fi
}

install_shellcheck() {
	echo "Installing shellcheck..."
	local -r SHELLCHECK_DOWNLOAD_DIR="${DOWNLOAD_DIR}/shellcheck-latest"
	rm -rf "$SHELLCHECK_DOWNLOAD_DIR"

	# Binary
	mkdir -p "$SHELLCHECK_DOWNLOAD_DIR"
	gh release download -R koalaman/shellcheck \
		-D "$SHELLCHECK_DOWNLOAD_DIR" \
		-p 'shellcheck-*.linux.*.tar.xz' \
		-p 'shellcheck-*.zip'

	if ! is_git_bash; then
		local arch_tag
		if is_arm64_architecture; then
			arch_tag='aarch64'
		else
			arch_tag='amd64'
		fi

		local -r filename_pattern="shellcheck-*.linux.$(uname -m).tar.xz"
		local -r filepath="$(find "$SHELLCHECK_DOWNLOAD_DIR" -name "$filename_pattern")"

		tar -xJv -C "$SHELLCHECK_DOWNLOAD_DIR" --strip-components=1 \
			-f "$filepath"
		sudo cp "${SHELLCHECK_DOWNLOAD_DIR}/shellcheck" /usr/bin/

		# Man page
		if does_command_exist pandoc; then
			wget -qO "${SHELLCHECK_DOWNLOAD_DIR}/shellcheck.1.md" \
				"https://raw.githubusercontent.com/koalaman/shellcheck/master/shellcheck.1.md"
			pandoc -s -f markdown-smart \
				-t man "${SHELLCHECK_DOWNLOAD_DIR}/shellcheck.1.md" \
				-o "${SHELLCHECK_DOWNLOAD_DIR}/shellcheck.1"
			sudo mv "${SHELLCHECK_DOWNLOAD_DIR}/shellcheck.1" /usr/share/man/man1
		fi
	else
		unzip "$SHELLCHECK_DOWNLOAD_DIR"/shellcheck-*.zip \
			-d "$XDG_BIN_HOME"
	fi

	shellcheck --version

	echo "Installed shellcheck successfully!"
}

install_brew() {
	if ! is_git_bash && ! is_arm32_architecture && ! is_arm64_architecture; then
		echo "Installing brew..."
		if is_root; then
			install_apt_packages linuxbrew-wrapper
		else
			/bin/bash -c "$(curl -fsSL \
				https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		fi
		[[ -s /home/linuxbrew/.linuxbrew/bin/brew ]] \
			&& eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
		[[ -s "$HOME"/.linuxbrew/bin/brew ]] \
			&& eval "$("$HOME"/.linuxbrew/bin/brew shellenv)"
		brew --version
		echo "Installed brew successfully!"
	else
		return 0
	fi
}

install_vale() {
	local file_archive
	if is_x86_64; then
		echo "Installing vale..."
		file_archive='vale_*_Linux_64-bit.tar.gz'
		readonly file_archive

		local DOWNLOAD_DIR="$DOWNLOAD_DIR"
		rm -f "$DOWNLOAD_DIR"/*{Windows,Linux}*
		gh release download \
			-R errata-ai/vale \
			-p "$file_archive" \
			-D "$DOWNLOAD_DIR"
		local -r file_archive_path="$(find "$DOWNLOAD_DIR" -name "$file_archive")"
		tar -xzvf "$file_archive_path" --directory "$XDG_BIN_HOME" vale

		vale -v
		echo "Installed vale successfully!"
	fi
}

install_rename() {
	install_apt_packages rename
}

install_keychain() {
	if ! is_git_bash && has_sudo; then
		echo "Installing keychain..."
		install_apt_packages keychain
		keychain --version
		echo "Installed keychain successfully!"
	fi
}

install_tex() {
	echo "Installing tex..."
	local -r filename=install-tl-unx.tar.gz
	wget -q --show-progress \
		-O "$DOWNLOAD_DIR"/"$filename" \
		https://mirror.ctan.org/systems/texlive/tlnet/"$filename"
	tar -xzf "$DOWNLOAD_DIR"/"$filename" -C "$DOWNLOAD_DIR"
	sudo perl "$DOWNLOAD_DIR"/install-tl-"$(date +%Y%m%d)"/install-tl \
		-profile "$HOME"/.config/texlive.profile
	tex --version
	echo "Installed tex successfully!"
}

install_jq() {
	require dra
	if ! is_git_bash; then
		echo "Installing jq..."
		dra download stedolan/jq \
			--select jq-linux64 \
			--output "$XDG_BIN_HOME"/jq
		chmod u+x "$XDG_BIN_HOME"/jq
		jq --version
		echo "Installed jq successfully!"
	fi
}

install_cht.sh() {
	echo "Installing cht..."
	# Note: The package `rlwrap` is a required dependency to run in shell mode.
	install_apt_packages rlwrap
	curl https://cht.sh/:cht.sh >"${XDG_BIN_HOME}/cht.sh"
	chmod +x "${XDG_BIN_HOME}/cht.sh"
	cht.sh --help
	echo "Installed cht successfully!"
}

install_rustc() {
	echo "Installing rust..."
	if ! is_git_bash; then
		# C linker, `silicon`, `spotify-tui` and `spotifyd` dependencies.
		install_apt_packages expat libxml2-dev pkg-config libasound2-dev \
			libssl-dev libfreetype6-dev libexpat1-dev libxcb-composite0-dev \
			libssl-dev libxcb1-dev libxcb-render0-dev libxcb-shape0-dev \
			libxcb-xfixes0-dev libpulse-dev libdbus-1-dev xcb-proto libx11-dev \
			libx11-xcb-dev libxcursor-dev libfontconfig1-dev libxkbcommon-dev \
			libegl1-mesa-dev build-essential
		curl https://sh.rustup.rs -sSf | sh -s -- --no-modify-path -y --default-toolchain nightly
		# shellcheck disable=SC1091
		. "$CARGO_HOME"/env
	else
		wget -P "$DOWNLOAD_DIR" \
			https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe
		"$DOWNLOAD_DIR"/rustup-init.exe --no-modify-path -y
	fi
	rustc --version
	install_default_pkgs cargo
	echo "Installed rust successfully!"
}

install_nerd_fonts() {
	if ! is_git_bash; then
		local -r font_dir="$FONT_DIR"/fira-code-nerd
		local -r font_download_dir="$DOWNLOAD_DIR"/fira-code-nerd
		local -r font_zip=FiraCode.zip

		echo "Installing nerd fonts..."

		rm -rf "$font_dir" "$font_download_dir"
		mkdir -p "$font_dir" "$font_download_dir"

		gh release download -R ryanoasis/nerd-fonts \
			-p "$font_zip" \
			-D "$font_download_dir"
		unzip -qo "$font_download_dir"/"$font_zip" \
			-d "$font_download_dir"
		rm -f "$font_download_dir"/*Windows\ Compatible*
		cp "$font_download_dir"/Fira\ Code*.ttf "$font_dir"

		# Build font information cache files.
		fc-cache -fv "$font_dir"
		fc-list | grep -i 'FiraCode'

		echo "Installed nerd fonts successfully!"
	fi
}

install_font_awesome_fonts() {
	if ! is_git_bash; then
		local -r font_dir="$FONT_DIR"/font-awesome-6
		local -r download_dir="$DOWNLOAD_DIR"/font-awesome-6
		local -r font_zip='fontawesome-free-*-desktop.zip'
		local -r files_to_unzip="fontawesome-free-*-desktop/otfs/*"

		echo "Installing nerd fonts..."

		rm -rf "$font_dir" "$download_dir"
		mkdir -p "$font_dir" "$download_dir"

		gh release download -R FortAwesome/Font-Awesome \
			-p "$font_zip" \
			-D "$download_dir" \
			|| return
		local -r font_zip_file="$(find "$download_dir" -name "$font_zip")"
		unzip -qjo "$font_zip_file" "$files_to_unzip" \
			-d "$download_dir" \
			|| return
		cp "$download_dir"/Font\ Awesome*.otf "$font_dir" \
			|| return

		# Build font information cache files.
		fc-cache -fv "$font_dir"
		fc-list | grep "$font_dir"

		echo "Installed nerd fonts successfully!"
	fi
}

install_dotenv-linter() {
	if ! is_arm32_architecture; then
		echo "Installing dotenv-linter..."
		curl -sSfL https://raw.githubusercontent.com/dotenv-linter/dotenv-linter/master/install.sh \
			| sh -s -- -b "$XDG_BIN_HOME"
		dotenv-linter --version
		echo "Installed dotenv-linter successfully!"
	fi
}

install_asdf_plugin() {
	if [[ -z ${1:-1} ]]; then
		echo "No plugin argument supplied"
		return 1
	fi

	local version='latest'

	if [[ -n ${2-} ]]; then
		version="$2"
	fi

	local plugin_git_repo=''

	case "${1}" in
		nodejs)
			plugin_git_repo='https://github.com/asdf-vm/asdf-nodejs.git'
			if [[ -n $version ]]; then
				version='lts'
			fi
			;;
		python)
			plugin_git_repo='https://github.com/asdf-community/asdf-python.git'
			install_python_deps
			;;
		golang)
			plugin_git_repo='https://github.com/kennyp/asdf-golang.git'
			;;
		ruby)
			plugin_git_repo='https://github.com/asdf-vm/asdf-ruby.git'
			install_ruby_deps
			;;
		java)
			version='openjdk-17.0.2'
			;;
		perl)
			plugin_git_repo='https://github.com/ouest/asdf-perl.git'
			;;
		R)
			plugin_git_repo='https://github.com/asdf-community/asdf-r.git'
			install_apt_packages build-essential libcurl3-dev libreadline-dev gfortran \
				liblzma-dev liblzma5 libbz2-1.0 libbz2-dev \
				xorg-dev libbz2-dev liblzma-dev libpcre2-dev \
				build-essential libcurl4-openssl-dev libssl-dev libxml2-dev r-base || return
			export R_EXTRA_CONFIGURE_OPTIONS='--enable-R-shlib --with-cairo'
			;;
		php)
			plugin_git_repo='https://github.com/asdf-community/asdf-php.git'
			install_apt_packages autoconf bison build-essential curl gettext git \
				libgd-dev libcurl4-openssl-dev libedit-dev libicu-dev libjpeg-dev \
				libmysqlclient-dev libonig-dev libpng-dev libpq-dev libreadline-dev \
				libsqlite3-dev libssl-dev libxml2-dev libzip-dev openssl pkg-config \
				re2c zlib1g-dev
			;;
		lua)
			install_apt_packages linux-headers-"$(uname -r)" build-essential
			plugin_git_repo='https://github.com/Stratus3D/asdf-lua.git'
			;;
		direnv)
			plugin_git_repo='https://github.com/asdf-community/asdf-direnv.git'
			;;
		*) ;;
	esac

	echo "Installing ${1} plugin from ${plugin_git_repo}"
	asdf plugin add "${1}" "$plugin_git_repo"
	case "${1}" in
		direnv)
			asdf "${1}" setup --shell "$SHELL" --version "$version"
			;;
		*)
			cd ~ || exit
			asdf direnv local "${1}" "$version"
			cd - || exit
			;;
	esac

	asdf global "${1}" "$version"
}

install_default_pkgs() {
	local -r pkg_mgr="${1}"

	if [[ -z $pkg_mgr ]]; then
		echo "No package manager supplied."
		return 1
	fi

	local -r pkg_list_file="${DEFAULT_PKGS_DIR}/${pkg_mgr}.list"
	local -a install_cmd=("$pkg_mgr")
	local -a install_opts=()
	local max_procs=1
	local packages
	packages=$(sed '/^\s*#/d' "$pkg_list_file")

	# Evaluator `{a,b}` brace expansion.
	eval packages="($packages)"

	# Convert array to a list delimited by newlines.
	packages=$(echo "${packages[*]}" | tr ' ' '\n')

	echo "Installing default ${pkg_mgr} packages"

	case ""${1} in
		pnpm)
			packages=$(echo "$packages" | tr '\n' ' ')
			install_cmd+=(install)
			install_opts+=(-g)
			;;
		cargo)
			install_cmd+=(install)
			;;
		cargo-binstall)
			install_cmd+=()
			install_opts+=(--no-confirm --no-symlinks)
			;;
		espanso)
			if is_git_bash; then
				install_cmd[0]+='.cmd'
			fi

			max_procs=$(nproc)
			install_cmd+=(install)
			install_opts+=(--force)
			;;
		pip | pip3)
			packages=$(echo "$packages" | tr '\n' ' ')
			install_cmd+=(install)
			install_opts+=(--upgrade --user)
			;;
		pipx)
			max_procs=$(nproc)
			install_cmd+=(install)
			;;
		gem)
			packages=$(echo "$packages" | tr '\n' ' ')
			install_cmd+=(install)
			;;
		go)
			install_cmd+=(install)
			;;
		brew)
			packages=$(echo "$packages" | tr '\n' ' ')
			install_cmd+=(install)
			;;
		*) ;;
	esac

	if [[ -n $2 ]]; then
		install_opts+=("${@:2}")
	fi

	# Filter out comments starting with $(#` and delay brace expansion
	# (https://superuser.com/a/519019).
	echo "$packages" \
		| xargs --verbose --no-run-if-empty --max-procs="$max_procs" --replace="{}" \
			bash -c "${install_cmd[*]} ${install_opts[*]} {}"

	# Post install steps.
	case "${1}" in
		espanso)
			espanso restart
			espanso package list
			;;
		*) ;;
	esac

	echo "Installed default ${1} packages successfully!"
}

install_espanso() {
	echo "Installing espanso"
	if is_git_bash; then
		winget install espanso
	fi
	espanso --version
	echo "Installed espanso successfully!"
	install_default_pkgs espanso
}

install_nircmd() {
	echo "Installing nircmd"
	if is_git_bash; then
		wget -P "$DOWNLOAD_DIR" http://www.nirsoft.net/utils/nircmd-x64.zip
		unzip -o -j -d "$XDG_BIN_HOME" "$DOWNLOAD_DIR"/nircmd-x64.zip nircmd.exe
	fi
	nircmd --version
	echo "Installed nircmd successfully!"
}

install_check_if_email_exists() {
	echo "Installing check_if_email_exists"
	if is_arm32_architecture; then
		git get https://github.com/reacherhq/check-if-email-exists
		cd "$HOME"/git/github.com/reacherhq/check-if-email-exists || return 1
		cargo build --release
		mv ./target/release/check_if_email_exists "$XDG_BIN_HOME"/check-if-email-exists
		cd -- || return 1
	else
		local file_to_download=''
		if is_arm64_architecture; then
			file_to_download+='*aarch64-'
		else
			file_to_download+='*x86_64-'
		fi

		if ! is_git_bash; then
			file_to_download+='unknown-linux-gnu'
		else
			file_to_download+='pc-windows-msvc'
		fi

		file_to_download+='*'
		rm -f "$DOWNLOAD_DIR"/"$file_to_download"
		gh release download -R reacherhq/check-if-email-exists \
			-p "$file_to_download" \
			-D "$DOWNLOAD_DIR"
		local -r filename="$(find "$DOWNLOAD_DIR" -name "$file_to_download")"
		tar xzfv "$filename" -C "$XDG_BIN_HOME"
	fi
	check_if_email_exists --version
	echo "Installed installing check_if_email_exists successfully!"
}

install_rustdesk() {
	if ! is_git_bash && ! is_arm32_architecture; then
		echo "Installing rustdesk"
		# Use `gh` to download the debian release file from the GitHub of
		# `rustdesk`.
		gh release download -R rustdesk/rustdesk \
			-p "rustdesk-*.deb" \
			-D "$DOWNLOAD_DIR"
		# Use `dpkg` to install the downloaded file.
		sudo dpkg -i "$DOWNLOAD_DIR"/rustdesk-*.deb
		rustdesk --version
		echo "Installed rustdesk successfully!"
	fi
}

install_flatpak() {
	if ! is_git_bash; then
		echo "Installing flatpak"
		if is_ubuntu_os || is_wsl; then
			install_apt_packages flatpak gnome-software-plugin-flatpak
			sudo flatpak remote-add --if-not-exists flathub \
				https://flathub.org/repo/flathub.flatpakrepo
		elif is_raspbian_os; then
			install_apt_packages flatpak
		fi
		flatpak --version
		echo "Installed flatpak successfully!"
	fi
}

install_node() {
	if is_ubuntu_os; then
		echo "Installing node..."
		curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
		install_apt_packages nodejs build-essential
		node --version
		echo "Installed node successfully!"
	fi
}

install_poetry() {
	if ! is_git_bash; then
		echo "Installing poetry..."
		curl -sSL https://install.python-poetry.org | python3 -
		poetry --version
		echo "Installed poetry successfully!"
	fi
}

install_volta() {
	if ! is_git_bash; then
		echo "Installing volta..."
		curl https://get.volta.sh | bash -s -- --skip-setup
		volta --version
		echo "Installed volta successfully!"
	fi
}

install_pnpm() {
	if ! is_git_bash; then
		echo "Installing pnpm..."
		wget -qO- https://get.pnpm.io/install.sh | sh -
		# Restoreing changes to dotfile.
		dot restore "$HOME"/.bashrc "$ZDOTDIR"/.zshrc
		pnpm --version
		echo "Installed pnpm successfully!"
	fi
}

install_curl() {
	if is_ubuntu_os; then
		echo "Installing curl..."
		install_apt_packages curl
		curl --version
		echo "Installed curl successfully!"
	fi
}

install_lua-language-server() {
	echo "Installing lua-language-server..."
	if is_git_bash; then
		local -r file_pattern='lua-language-server-*-win32-x64.zip'
		local -r install_dir="$XDG_DATA_HOME"/lua-language-server
		gh release download --repo LuaLS/lua-language-server \
			--pattern "$file_pattern" \
			--dir "$DOWNLOAD_DIR" \
			--clobber \
			|| return
		local -r file="$(fd --glob "$file_pattern" "$DOWNLOAD_DIR")"
		rm -rf "$install_dir" && mkdir -p "$install_dir"
		unzip -q "$file" -d "$install_dir"
	else
		brew install lua-language-server
	fi
	command -v lua-language-server || return
	echo "Installed lua-language-server successfully!"
}

install_pinentry-tty() {
	echo "Installing pinentry-tty..."
	install_apt_packages pinentry-tty
	echo "Installed pinentry-tty successfully!"
}

install_gcloud() {
	if is_ubuntu_os; then
		echo "Installing gcloud..."

		# install apt-transport-https ca-certificates gnupg
		install_apt_packages apt-transport-https ca-certificates gnupg

		# Add the gcloud CLI distribution URI as a package source.
		echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] \
			https://packages.cloud.google.com/apt cloud-sdk main" \
			| sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null

		# Import the Google Cloud public key.
		curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
			| sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

		# Update and install the gcloud CLI
		install_apt_packages google-cloud-sdk

		# Initialize the gcloud environment.
		gcloud init

		echo "Installed gcloud successfully!"
	fi
}

install_terraform() {
	if is_ubuntu_os; then
		echo "Installing terraform..."
		install_apt_packages gnupg software-properties-common

		# Install the HashiCorp GPG key.
		wget -O- https://apt.releases.hashicorp.com/gpg \
			| gpg --dearmor \
			| sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

		#  Verify the key's fingerprint.
		gpg --no-default-keyring \
			--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
			--fingerprint

		# Add the official HashiCorp repository to your system.
		echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
			| sudo tee /etc/apt/sources.list.d/hashicorp.list

		install_apt_packages terraform

		terraform -help
		echo "Installed terraform successfully!"
	fi
}

install_bun() {
	curl -fsSL https://bun.sh/install | bash
}

# https://github.com/helix-editor/helix/wiki/Debugger-Configurations#codelldb-
install_codelldb() {
	local -r download_file=codelldb-x86_64-linux.vsix
	cd "$DOWNLOAD_DIR" || return
	gh release download --repo vadimcn/vscode-lldb \
		--pattern "$download_file" \
		--clobber
	unzip -qo "$download_file" "extension/adapter/*" "extension/lldb/*"
	rm -rf "$download_file" "$XDG_DATA_HOME"/codelldb
	mv extension "$XDG_DATA_HOME"/codelldb
	ln -sf "$XDG_DATA_HOME"/codelldb/adapter/codelldb "$XDG_BIN_HOME"
	codelldb -h
	cd - >/dev/null || return
}

install_tmux() {
	echo 'https://github.com/tmux/tmux/wiki/Installing'
	git get https://github.com/tmux/tmux.git
	cd "$GHQ_ROOT"/github.com/tmux/tmux || return
	sh autogen.sh
	./configure --prefix "$XDG_LOCAL_HOME"
	make
	make install
	cd - || return
}

# https://github.com/neovim/neovim/wiki/Installing-Neovim#install-from-source
install_nvim() {
	echo "Installing neovim..."
	git get https://github.com/neovim/neovim.git
	cd "$GHQ_ROOT"/github.com/neovim/neovim || return
	install_apt_packages ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl doxygen
	make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${1:-$XDG_LOCAL_HOME}" || return
	make install || return
	nvim --version
	cd - || return
	echo "Installed neovim successfully!"
}

# https://github.com/emacs-mirror/emacs/blob/master/INSTALL.REPO
# https://www.emacswiki.org/emacs/BuildingEmacs
install_emacs() {
	echo "Installing emacs..."
	mkdir -p "$GHQ_ROOT"/github.com/emacs-mirror
	git clone --filter=blob:none --depth=1 https://github.com/emacs-mirror/emacs \
		"$GHQ_ROOT"/github.com/emacs-mirror/emacs >/dev/null 2>&1
	cd "$GHQ_ROOT"/github.com/emacs-mirror/emacs || return
	install_apt_packages autoconf texinfo libgtk-3-dev libwebkit2gtk-4.0-dev \
		libgccjit-9-dev libjansson-dev editorconfig pandoc
	sudo apt build-dep -qqy emacs
	./autogen.sh
	./configure --with-native-compilation --with-json \
		--with-cairo --with-xwidgets --with-x-toolkit=gtk3 \
		--prefix="${1:-$XDG_LOCAL_HOME}" || return
	make --jobs "$(nproc)" || return
	make install || return
	emacs --version || return
	doom install --force || return
	doom doctor || return
	cd - || return
	echo "Installed emacs successfully!"
}

install_hx() {
	echo "Installing hx..."
	git get https://github.com/helix-editor/helix.git
	cd "$GHQ_ROOT"/github.com/helix-editor/helix || return
	rustup override set nightly
	cargo install --locked --path helix-term
	hx --version
	cd - || return
	echo "Installed hx successfully!"
}

install_pwsh() {
	echo 'Installing pwsh...'
	local -r file_pattern='powershell_*-1.deb_amd64.deb'
	gh release download --repo PowerShell/PowerShell \
		--pattern "$file_pattern" \
		--dir "$DOWNLOAD_DIR"
	local -r file="$(fd --glob "$file_pattern" "$DOWNLOAD_DIR")"
	sudo apt install -y "$file"
	pwsh --version
	echo 'Finished installing pwsh!'
}

install_direnv() {
	echo 'Installing direnv...'
	export bin_path=$XDG_BIN_HOME
	curl -sfL https://direnv.net/install.sh | bash
	direnv --version
	echo 'Finished installing direnv!'
}

install_vscode_js_debug() {
	git get https://github.com/microsoft/vscode-js-debug.git
	z "$GHQ_ROOT"/github.com/microsoft/vscode-js-debug
	# https://github.com/mxsdev/nvim-dap-vscode-js/issues/19#issuecomment-1333564516
	git switch -d v1.68.0
	pnpm import
	pnpm install
	pnpm compile
	z -
}

install_vscode_node_debug2() {
	git get https://github.com/microsoft/vscode-node-debug2.git
	z "$GHQ_ROOT"/github.com/microsoft/vscode-node-debug2
	# https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#javascript
	pnpm import
	pnpm install
	NODE_OPTIONS=--no-experimental-fetch pnpm build
	z -
}

install_vscode_bash_debug() {
	git get https://github.com/rogalmic/vscode-bash-debug.git
	z "$GHQ_ROOT"/github.com/rogalmic/vscode-bash-debug
	pnpm import
	pnpm install
	pnpm compile
	z -
}

install_python_deps() {
	install_apt_packages build-essential libssl-dev zlib1g-dev \
		libbz2-dev libreadline-dev libsqlite3-dev curl \
		libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
}

install_ruby_deps() {
	install_apt_packages autoconf bison build-essential libssl-dev \
		libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev \
		libgdbm6 libgdbm-dev libdb-dev
}

# https://github.com/neovim/neovim/wiki/Installing-Neovim#install-from-source
install_dbus-broker() {
	echo "Installing dbus-broker..."
	git get https://github.com/bus1/dbus-broker.git
	cd "$GHQ_ROOT"/github.com/bus1/dbus-broker || return
	install_apt_packages meson pkg-config python-docutils dbus systemd expat \
		libsystemd-dev
	meson setup build || return
	meson compile -C build || return
	meson test -C build || return
	sudo meson install -C build || return
	sudo systemctl enable dbus-broker.service
	sudo systemctl start dbus-broker.service
	cd - || return
	echo "Installed dbus-broker successfully!"
}

# endregion Installation.

# region Boolean functions

is_bash_shell() {
	[[ -n ${BASH_VERSION} ]]
}

is_zsh_shell() {
	[[ -n ${ZSH_NAME} ]]
}

is_login_shell() {
	{ is_bash_shell && shopt -q login_shell; } \
		|| { is_zsh_shell && [[ -o login ]]; }
}

is_interactive_shell() {
	{ is_bash_shell && [[ $- == *i* ]]; } \
		|| { is_zsh_shell && [[ -o interactive ]]; }
}

is_windows_os() {
	filter_system_information "Msys|WSL"
}

is_linux_os() {
	filter_system_information "Linux"
}

# Source: https://unix.stackexchange.com/a/210656/460126
is_debian_os() {
	[[ -f "/etc/debian_version" ]]
}

is_ubuntu_os() {
	cat /etc/*ease | grep -qE "ubuntu"
}

is_git_bash() {
	filter_system_information "Msys"
}

is_wsl() {
	filter_system_information "WSL"
}

is_ssh_session() {
	[[ $SSH_CONNECTION != "" ]]
}

is_root() {
	[[ "$(id -u)" == 0 ]]
}

is_asdf_plugin_installed() {
	asdf plugin list 2>&1 | grep -q "$1" \
		&& asdf list "$1" 2>&1 | grep -q "\."
}

is_arm32_architecture() {
	lscpu | grep -q armv7
}

is_arm64_architecture() {
	lscpu | grep -q aarch64
}

is_x86_64() {
	[[ $(uname -m) == x86_64 ]]
}

has_sudo() {
	local prompt

	if prompt=$(sudo -nv 2>&1); then
		return 0
	elif echo "$prompt" | grep -q '^sudo:'; then
		return 0
	else
		return 1
	fi
}

does_function_exist() {
	declare -f -F "$1" >/dev/null 2>&1
}

does_command_exist() {
	command -v "$1" >/dev/null
}

# endregion Boolean functions

count_files_in_directory() {
	# shellcheck disable=SC2012
	ls -1 "${@}" | wc -l
}

download_alacritty_config_template() {
	gh release download -R alacritty/alacritty \
		-p alacritty.yml \
		-D "$DOWNLOAD_DIR"
	mv "${HOME}/Downloads/alacritty.yml" \
		"${HOME}/.config/alacritty/alacritty-template.yml"
}

init_direnv() {
	cat >|.envrc <<EOF
#!/usr/bin/env sh

source_up_if_exists .envrc
EOF
	direnv allow
}

# Create a new directory and enter it
mkd() {
	mkdir -p "$@" && cd "$_" || exit
}

# Change working directory to the top-most Finder window location
cdf() { # short for `cdfinder`
	cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')" || exit
}

# Create a .tar.gz archive, using `zopfli`, `pigz` or `gzip` for compression
targz() {
	local tmpFile="${*%/}.tar"
	tar -cvf "$tmpFile" --exclude=".DS_Store" "${@}" || return 1

	size=$(
		stat -f"%z" "$tmpFile" 2>/dev/null # macOS `stat`
		stat -c"%s" "$tmpFile" 2>/dev/null # GNU `stat`
	)

	local cmd=""
	if ((size < 52428800)) && hash zopfli 2>/dev/null; then
		# the .tar file is smaller than 50 MB and Zopfli is available; use it
		cmd="zopfli"
	else
		if hash pigz 2>/dev/null; then
			cmd="pigz"
		else
			cmd="gzip"
		fi
	fi

	echo "Compressing .tar ($((size / 1000)) kB) using \`${cmd}\`…"
	"$cmd" -v "$tmpFile" || return 1
	[[ -f $tmpFile ]] && rm "$tmpFile"

	zippedSize=$(
		stat -f"%z" "${tmpFile}.gz" 2>/dev/null # macOS `stat`
		stat -c"%s" "${tmpFile}.gz" 2>/dev/null # GNU `stat`
	)

	echo "${tmpFile}.gz ($((zippedSize / 1000)) kB) created successfully."
}

# Determine size of a file or total size of a directory
fs() {
	if du -b /dev/null >/dev/null 2>&1; then
		local arg=-sbh
	else
		local arg=-sh
	fi
	if [[ -n $* ]]; then
		du "$arg" -- "$@"
	else
		du "$arg" .[^.]* ./*
	fi
}

# Use Git's colored diff when available
if hash git &>/dev/null; then
	function diff() {
		git diff --no-index --color-words "$@"
	}
fi

# Combine `bat` with `git diff` to view lines around code changes with proper
# syntax highlighting.
batdiff() {
	git diff --name-only --diff-filter=d | xargs bat --diff
}

# Create a data URL from a file
dataurl() {
	local mimeType
	mimeType=$(file -b --mime-type "$1")
	if [[ ${mimeType} == text/* ]]; then
		mimeType="${mimeType};charset=utf-8"
	fi
	echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# Start a PHP server from a directory, optionally specifying the port
# (Requires PHP 5.4.0+.)
phpserver() {
	local port="${1:-4000}"
	local ip
	ip=$(ipconfig getifaddr en1)
	sleep 1 && open "http://${ip}:${port}/" &
	php -S "${ip}:${port}"
}

# Compare original and gzipped file size
gz() {
	local origsize
	local gzipsize
	local ratio
	origsize=$(wc -c <"$1")
	gzipsize=$(gzip -c "$1" | wc -c)
	ratio=$(echo "${gzipsize} * 100 / ${origsize}" | bc -l)
	printf "orig: %d bytes\n" "$origsize"
	printf "gzip: %d bytes (%2.2f%%)\n" "$gzipsize" "$ratio"
}

# Run `dig` and display the most useful info
digga() {
	dig +nocmd "$1" any +multiline +noall +answer
}

# Show all the names (CNs and SANs) listed in the SSL certificate
# for a given domain
getcertnames() {
	if [[ ${1} == "" ]]; then
		echo "ERROR: No domain specified."
		return 1
	fi

	local domain="${1}"
	echo "Testing ${domain}…"
	echo "" # newline

	local tmp
	tmp=$(echo -e "GET / HTTP/1.0\nEOT" \
		| openssl s_client -connect "${domain}:443" -servername "$domain" 2>&1)

	if [[ $tmp == *"-----BEGIN CERTIFICATE-----"* ]]; then
		local certText
		certText=$(echo "$tmp" \
			| openssl x509 -text -certopt "no_aux, no_header, no_issuer, no_pubkey, \
				no_serial, no_sigdump, no_signame, no_validity, no_version")
		echo "Common Name:"
		echo "" # newline
		echo "$certText" | grep "Subject:" | sed -e "s/^.*CN=//" | sed -e "s/\/emailAddress=.*//"
		echo "" # newline
		echo "Subject Alternative Name(s):"
		echo "" # newline
		echo "$certText" | grep -A 1 "Subject Alternative Name:" \
			| sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2
		return 0
	else
		echo "ERROR: Certificate not found."
		return 1
	fi
}

# Normalize `open` across Linux, macOS, and Windows.
# This is needed to make the `o` function (see below) cross-platform.
if [[ "$(uname -s)" != 'Darwin' ]]; then
	if grep -q Microsoft /proc/version; then
		# Ubuntu on Windows using the Linux subsystem
		alias open='explorer.exe'
	else
		alias open='xdg-open'
	fi
fi

# `o` with no arguments opens the current directory, otherwise opens the given
# location
o() {
	if [[ $# -eq 0 ]]; then
		open .
	else
		open "$@"
	fi
}

# `tre` is a shorthand for `tree` with hidden files and color enabled, ignoring
# the `.git` directory, listing directories first. The output gets piped into
# `less` with options to preserve color and line numbers, unless the output is
# small enough for one screen.
treee() {
	tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX
}

drop_mysql_databases() {
	echo "Deleting databases..."

	sudo mysql -u root --table=false -e "SHOW DATABASES" \
		| grep -v -e Database -e mysql -e sys -e schema \
		| gawk '{print "DROP DATABASE " $1 ";"}' \
		| sudo mysql -u root

	echo "Done."
}

# Safer wget | bash'ing
wgetbash() {
	file=$(mktemp wgetbash.XXX.sh) || {
		echo "Failed creating file"
		return
	}

	wget "$1" -qO "$file" || {
		echo "Failed to wget file"
		return
	}

	"$EDITOR" "$file" || {
		echo "Editor quit with error code"
		return
	}

	bash "$file"
	rm "$file"
}

pass_bw() {
	bw get password "$1" | xclip -se c
}

start_ssh_agent() {
	local -r env="$HOME"/.ssh/agent.env

	# shellcheck disable=SC1090
	function agent_load_env() {
		test -f "$env" && . "$env" >|/dev/null
	}

	function agent_start() {
		(
			umask 077
			ssh-agent >|"$env"
		)

		# shellcheck disable=SC1090
		. "$env" >|/dev/null
	}

	agent_load_env

	# {agent_run_state}: 0=agent running w/ key; 1=agent w/o key; 2= agent not
	# running
	local -r agent_run_state="$(
		ssh-add -l >|/dev/null 2>&1
		echo $?
	)"

	if [[ $SSH_AUTH_SOCK == "" ]] || [[ $agent_run_state == 2 ]]; then
		agent_start
	fi
}

start_ssh_keychain() {
	eval "$(keychain --eval --quiet --agents ssh,gpg --inherit any id_ed25519 \
		--absolute --dir "$XDG_DATA_HOME"/keychain "$@")"
}

filter_system_information() {
	uname -a | grep -q -E "$@"
}

switch_npm() {
	npm i -g npm@"${1}"
}

rename_file_ext() {
	if [[ $# != 2 ]]; then
		echo "Need to pass two file extensions"
		return 1
	fi
	#  -exec rename ."$1" ."$2" {} +

	find . -name "*.$1" -exec rename "s/\.$1$/.$2/" '{}' +
}

#   extract:  Extract most know archives with one command
#   ---------------------------------------------------------
extract() {
	if [[ -f $1 ]]; then
		case "$1" in
			*.tar.bz2) tar xjf "$1" ;;
			*.tar.gz) tar xzf "$1" ;;
			*.bz2) bunzip2 "$1" ;;
			*.rar) unrar e "$1" ;;
			*.gz) gunzip "$1" ;;
			*.tar) tar xf "$1" ;;
			*.tbz2) tar xjf "$1" ;;
			*.tgz) tar xzf "$1" ;;
			*.zip) unzip "$1" ;;
			*.Z) uncompress "$1" ;;
			*.7z) 7z x "$1" ;;
			*) echo "'$1' cannot be extracted via extract()" ;;
		esac
	else
		echo "'$1' is not a valid file"
	fi
}

is_raspbian_os() {
	grep -q -E 'raspbian' /etc/os-release
}

generate_ssh_key() {
	local -r keyfile="$HOME"/.ssh/id_ed25519"$([[ -n $1 ]] && echo _"$1")"
	local -r comment="$(whoami)@$(hostname)"
	ssh-keygen -t ed25519 -f "$keyfile" -C "$comment"
}

export_gpg_key() {
	gpg --export-secret-key --armor ABE9B748EEAE9E00 >|"$HOME"/.gnupg/secret.asc
	scp "$HOME"/.gnupg/secret.asc "${1}":"$HOME"/.gnupg
}

import_gpg_key() {
	gpg --import "$HOME"/.gnupg/secret.asc
	gpg --edit-key ABE9B748EEAE9E00 trust
	gpg --update-trustdb
}

fix_gnupg_perms() {
	# To fix the " gpg: WARNING: unsafe permissions on homedir '/home/path/to/user/.gnupg' " error
	# Make sure that the .gnupg directory and its contents is accessibile by your user.
	chown -R "$(whoami)" "$HOME"/.gnupg/
	# Also correct the permissions and access rights on the directory.
	chmod 600 "$HOME"/.gnupg/*
	chmod 700 "$HOME"/.gnupg
}

kill_detached_tmux_sessions() {
	tmux list-sessions -F '#{session_attached} #{session_id}' \
		| awk '/^0/{print $2}' \
		| xargs -n 1 tmux kill-session -t
}

# Symlinks sh related plugins into the custom plugin folders of sh plugin
# managers to enable them.
ln_sh_plugins() {
	local -r zsh_target_dir="$ZSH"/custom/plugins
	local -r bash_target_dir="$OSH"/custom/plugins
	local -ra sh_plugins=(
		Intersec/pyvenv-activate
	)

	local -ra zsh_plugins=(
		"${sh_plugins[@]}"
		zsh-users/zsh-autosuggestions
		zsh-users/zsh-completions
		zsh-users/zsh-syntax-highlighting
		dracula/zsh-syntax-highlighting
		marlonrichert/zsh-hist
	)

	local -ra bash_plugins=(
		"${sh_plugins[@]}"
	)

	mkdir -p "$zsh_target_dir"
	mkdir -p "$bash_target_dir"

	for plugin in "${zsh_plugins[@]}"; do
		local zsh_plugin_src="$HOME"/src/github.com/"$plugin"

		# Rename plugin to avoid namespace conflict.
		if [[ $plugin == dracula/zsh-syntax-highlighting ]]; then
			# Need to rename the file so that the plugin manager can interpret it as a
			# plugin.
			ln -sf "$zsh_plugin_src"/zsh-syntax-highlighting.sh \
				"$zsh_plugin_src"/zsh-syntax-highlighting-dracula.plugin.zsh

			# Remove lingering symlinks to avoid nesting symlinks.
			rm -rf "$zsh_target_dir"/zsh-syntax-highlighting-dracula
			ln -sf "$zsh_plugin_src" \
				"$zsh_target_dir"/zsh-syntax-highlighting-dracula
		else
			ln -sf "$zsh_plugin_src" "$zsh_target_dir"
		fi
	done

	for plugin in "${bash_plugins[@]}"; do
		ln -sf "$HOME"/src/github.com/"$plugin" "$bash_target_dir"
	done
}

ln_nvim_cfg() {
	ln -sf "$XDG_CONFIG_HOME"/neovim "$XDG_CONFIG_HOME"/nvim/lua/custom
	ln -sf "$XDG_CONFIG_HOME"/neovim/after "$XDG_CONFIG_HOME"/nvim
}

install_apt_packages() {
	if ! has_sudo; then
		return 1
	fi

	if ! dpkg-query -s "${@}" >/dev/null 2>&1; then
		echo "Updating apt cache..."
		sudo apt-get update
		echo "Installing apt packages..."
		sudo DEBIAN_FRONTEND=noninteractive apt-get -qq -o=Dpkg::Use-Pty=0 install \
			"${@}"
	fi
}

uninstall_global_npm_pkgs() {
	npm ls -gp --depth=0 \
		| awk -F/ '/node_modules/ && !/\/npm$/ {print $NF}' \
		| xargs npm -g rm
	npm ls -gp --depth=0 \
		| awk -F/ '/node_modules\/@/ {print $(NF-1)"/"$NF} /node_modules\/[^@]/ && !/\/npm$/ {print $NF}' \
		| xargs npm -g rm
}

generate_completions() {
	local -r shell="$(basename "$(readlink -f /proc/$$/exe)")"
	local -r command_to_complete="${1}"
	local -ra completion_cmd=("${@:2}")
	local -r bash_completion_file="$BASH_COMPLETION_USER_DIR"/completions/"$command_to_complete"
	local -r zsh_completion_file="$ZSH_USER_FPATH"/_"$command_to_complete"

	case "$shell" in
		# sed to strip ANSI escape codes. *cough* bw *cough*
		bash)
			if [[ ! -s ${bash_completion_file} ]]; then
				"${completion_cmd[@]}" | sed -e 's/\x1b\[[0-9;]*m//g' >|"$bash_completion_file"
			fi
			;;
		zsh)
			if [[ ! -s ${zsh_completion_file} ]]; then
				"${completion_cmd[@]}" | sed -e 's/\x1b\[[0-9;]*m//g' >|"$zsh_completion_file"
			fi
			;;
		*)
			echo "Invalid shell: ${shell}"
			return 1
			;;
	esac
}

kill_window_manager() {
	pkill -15 -t tty"$XDG_VTNR" Xorg
}

unexpand_inplace() {
	local -r tempfile="$(mktemp)"
	unexpand -t 2 --first-only "$1" >|"$tempfile"
	cp "$tempfile" "$1"
}

trim_trailing_whitespace() {
	sed -i 's/[ \t]*$//' "$@"
}

# Open search result in ddg on default browser.
search() {
	xdg-open https://duckduckgo.com/\?q="$*"
}

if asdf list direnv &>/dev/null; then
	# A shortcut for asdf managed direnv.
	direnv() {
		asdf exec direnv "$@"
	}
fi

install_wezterm_terminfo() {
	tempfile=$(mktemp) \
		&& curl -o "$tempfile" https://raw.githubusercontent.com/wez/wezterm/master/termwiz/data/wezterm.terminfo \
		&& tic -x -o "$TERMINFO" "$tempfile" \
		&& rm "$tempfile"
}

setup_windows() {
	winget import --import-file "$XDG_CONFIG_HOME"/windows/winget-pkgs.json
}

ls_glab_mr_map() {
	glab mr list "$@" \
		| tail +3 \
		| head -n -1 \
		| awk '{print $1 " " $(NF)}' \
		| tr -d '()'
}

update_tmux_env() {
	(
		unset SHLVL SSH_CONNECTION SSH_CLIENT SSH_TTY

		# Avoid triggering the starship prompt module in tmux server started by
		# systemd. Remove lingering SSH env vars.
		dbus-update-activation-environment --systemd --all >/dev/null 2>&1 \
			|| awk 'BEGIN{for(v in ENVIRON) print v}' | grep -iv -e awk -e lua -e ^_ \
			| xargs systemctl --user import-environment
		systemctl --user unset-environment SHLVL SSH_CONNECTION SSH_CLIENT SSH_TTY
		systemctl --user start tmux.service
	)
}

fix_ssh_perms() {
	chmod 700 "$HOME"/.ssh
	chmod 600 "$HOME"/.ssh/id_*
	chmod 644 "$HOME"/.ssh/{*.pub,authorized_keys}
}
