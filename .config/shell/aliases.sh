#!/usr/bin/env sh
#
# shellcheck disable=SC2154

# Alias to manage dotfiles git repo.
alias dot='git --git-dir="${HOME}"/.git --work-tree="${HOME}"'

# Shortcuts
alias dl="cd ~/Downloads"

# Always enable colored `grep` output
# Note: `GREP_OPTIONS="--color=auto"` is deprecated, hence the alias usage.
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Enable aliases to be sudo'ed
alias sudo='sudo '

# Get week number
alias week='date +%V'

# Get macOS Software Updates, and update installed Ruby gems, Homebrew, npm, and their installed packages
alias update='sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup; npm install npm -g; npm update -g; sudo gem update --system; sudo gem update; sudo gem cleanup'

# Show active network interfaces
alias ifactive="ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: active'"

# Flush Directory Service cache
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"

# Clean up LaunchServices to remove duplicates in the "Open With" menu
alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"

# Canonical hex dump; some systems have this symlinked
command -v hd >/dev/null || alias hd="hexdump -C"

# macOS has no `md5sum`, so use `md5` as a fallback
command -v md5sum >/dev/null || alias md5sum="md5"

# macOS has no `sha1sum`, so use `shasum` as a fallback
command -v sha1sum >/dev/null || alias sha1sum="shasum"

# JavaScriptCore REPL
jscbin="/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Resources/jsc"
# shellcheck disable=SC2139
[ -e "$jscbin" ] && alias jsc="$jscbin"
unset jscbin

# Trim new lines and copy to clipboard
alias c="tr -d '\n' | pbcopy"

# Recursively delete `.DS_Store` files
alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"

# Empty the Trash on all mounted volumes and the main HDD.
# Also, clear Apple's System Logs to improve shell startup speed.
# Finally, clear download history from quarantine. https://mths.be/bum
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl; sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent'"

# Show/hide hidden files in Finder
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# Hide/show all desktop icons (useful when presenting)
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

# Merge PDF files, preserving hyperlinks
# Usage: `mergepdf input{1,2,3}.pdf`
alias mergepdf='gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=_merged.pdf'

# Disable Spotlight
alias spotoff="sudo mdutil -a -i off"
# Enable Spotlight
alias spoton="sudo mdutil -a -i on"

# PlistBuddy alias, because sometimes `defaults` just doesn't cut it
alias plistbuddy="/usr/libexec/PlistBuddy"

# Airport CLI alias
alias airport='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport'

# Intuitive map function
# For example, to list all directories that contain a certain file:
# find . -name .gitattributes | map dirname
alias map="xargs -n1"

# One of @janmoesen's ProTip™s
for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
	# shellcheck disable=SC2139
	alias "${method}=lwp-request -m '${method}'"
done

# Stuff I never really use but cannot delete either because of http://xkcd.com/530/
alias stfu="osascript -e 'set volume output muted true'"
alias pumpitup="osascript -e 'set volume output volume 100'"

# Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"

# Lock the screen (when going AFK)
alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"

# Reload the shell (i.e. invoke as a login shell)
# shellcheck disable=SC2139
alias reload="exec ${SHELL} -l"

# Print each PATH entry on a separate line
alias path='echo "${PATH}" | tr ":" "\n"'

# To make cp uninteractive by default
unalias cp 2>/dev/null

# Produce an ASCII tree of the directory structure with directoreis listed
# first.
alias tree="tree --dirsfirst --charset=ascii"

# region ls vs. exa

alias ls="ls --color"
alias ll="ls -l --almost-all --classify --group-directories-first --human-readable --color"

# Override `ls` with `exa` if it exists.
if command -v lsd >/dev/null 2>&1; then
	alias ls=lsd
	alias ll='lsd --long --almost-all --classify --group-directories-first'
fi

# endregion ls vs. exa

# xclip workaround in WSL 2.
[ -f '/mnt/c/Windows/System32/clip.exe' ] \
	&& alias xclip='/mnt/c/Windows/System32/clip.exe'

alias conventional-changelog='conventional-changelog -p conventionalcommits -n "${XDG_CONFIG_HOME}"/conventional-changelog/config.js'
alias yarn='yarn --use-yarnrc "${XDG_CONFIG_HOME}"/yarn/config'
alias sqlite='sqlite3 -init "${XDG_CONFIG_HOME}"/sqlite3/sqliterc'
mkdir -p "$XDG_CACHE_HOME"/wget
alias wget='wget --hsts-file="${XDG_CACHE_HOME}"/wget/hsts'
mkdir -p "$XDG_STATE_HOME"/units
alias units='units --history "${XDG_STATE_HOME}"/units/history'
alias xbindkeys='xbindkeys --file "${XDG_CONFIG_HOME}"/xbindkeys/config'
mkdir -p "$XDG_DATA_HOME"/keychain
command -v keychain >/dev/null && alias keychain='keychain --absolute --dir "${XDG_DATA_HOME}"/keychain'
alias info='info --vi-keys'
if uname -a | grep -q 'Msys'; then
	alias espanso='espanso.cmd'
fi
command -v bq >/dev/null && alias bq='bq --bigqueryrc "${XDG_CONFIG_HOME}"/bigquery/bigqueryrc'
command -v shfmt >/dev/null && alias shfmt='shfmt -ci -bn --simplify'
alias watch='watch --color'
alias muc='muc --count 16'
alias ec='emacsclient --tty'
alias ruby='ruby --yjit'
alias restart-tmux='systemctl --user stop tmux && update_tmux_env && tmux attach'
command -v watchexec >/dev/null \
	&& alias watchexec='watchexec --project-origin . --restart --clear=reset --timings --notify --bell'
alias xidlehook-client='xidlehook-client --socket $XIDLEHOOK_SOCK'
