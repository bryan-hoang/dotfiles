# Read-only work-machine baseline (PowerShell 7, Windows). Reports paths,
# types, states, and hashes only; never file contents, URLs, or local-input
# values. Classifies every differing path as behind, local edit, or type change
# against the home checkout's HEAD, lists unclassified paths, and exits 1 if
# any exist.
#
# Read-only rules: Git runs only plumbing reads, with optional locks off; the
# one porcelain call (submodule status, Git 2.40+) reads attributes from the
# empty tree and no attributes file, so no clean filter runs unless a
# submodule's own info/attributes names one. mise runs once with its cache sent
# to NUL and no network.
#
#   pwsh -NoProfile -File work-baseline.ps1 -ConversionTip <sha> [-TipRepo <git dir>]
#
# -TipRepo is any local repository holding the conversion commit (default: the
# checkout's .git).
param(
	[Parameter(Mandatory)][string]$ConversionTip,
	[string]$HomeRoot = [Environment]::GetFolderPath('UserProfile'),
	[string]$Checkout = $HomeRoot,
	[string]$TipRepo = (Join-Path $Checkout '.git'),
	[string]$HistoryStore = (Join-Path $HomeRoot '.local\state\mise\history\repo.git'),
	[switch]$SkipWsl
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$emptyTree = '4b825dc642cb6eb9a060e54bf8d69288fbee4904'
$originPattern = 'github\.com[:/]bryan-hoang/dotfiles(\.git)?/?$'
$localInputs = '.config/mise/config.local.toml', '.config/git/machine.gitconfig', '.config/mise/config.windows.local.toml'
$envNames = 'MISE_AUTO_INSTALL', 'MISE_OFFLINE', 'MISE_CACHE_DIR', 'GIT_OPTIONAL_LOCKS', 'GIT_TERMINAL_PROMPT', 'WSL_UTF8'
$savedEnv = $envNames | ForEach-Object { [Environment]::GetEnvironmentVariable($_) }
$env:MISE_AUTO_INSTALL = '0'
$env:GIT_OPTIONAL_LOCKS = '0'
$env:GIT_TERMINAL_PROMPT = '0'
$HomeRoot = [IO.Path]::GetFullPath($HomeRoot)
$Checkout = [IO.Path]::GetFullPath($Checkout)
$gitDir = Join-Path $Checkout '.git'

function ReadGit { $o = & git @args 2>$null; if ($LASTEXITCODE) { $null } else { $o } }
function BlobId([byte[]]$bytes) {
	$h = [Security.Cryptography.IncrementalHash]::CreateHash('SHA1')
	$h.AppendData([Text.Encoding]::ASCII.GetBytes("blob $($bytes.Length)`0"))
	$h.AppendData($bytes)
	[Convert]::ToHexString($h.GetHashAndReset()).ToLowerInvariant()
}
# type: absent, file, link, or dir; id: Git blob id of the bytes or link target.
function Live([string]$path) {
	$fi = [IO.FileInfo]::new($path)
	if ([int]$fi.Attributes -eq -1) { return @{ type = 'absent'; id = '-' } }
	if ($fi.LinkTarget) { return @{ type = 'link'; id = BlobId ([Text.Encoding]::UTF8.GetBytes(($fi.LinkTarget -replace '\\', '/'))) } }
	if ($fi.Attributes -band [IO.FileAttributes]::Directory) { return @{ type = 'dir'; id = '-' } }
	$bytes = [IO.File]::ReadAllBytes($path)
	# With core.autocrlf=true Git checks text out with CRLF and hashes it as LF.
	$lf = if ($autocrlf -and [Array]::IndexOf($bytes, [byte]0) -lt 0 -and [Array]::IndexOf($bytes, [byte]13) -ge 0) {
		$latin1 = [Text.Encoding]::Latin1
		BlobId $latin1.GetBytes($latin1.GetString($bytes).Replace("`r`n", "`n"))
	}
	@{ type = 'file'; id = BlobId $bytes; lf = $lf }
}
function Same($live, $entry) { $entry -and ($live.id -eq $entry.id -or ($live.lf -and $live.lf -eq $entry.id)) }
function Tree([string]$dir, [string]$rev) {
	$map = @{}
	foreach ($e in ((& git --git-dir $dir ls-tree -r -z --full-tree $rev) -join "`n") -split "`0") {
		if (-not $e) { continue }
		$meta, $p = $e.TrimStart("`n") -split "`t", 2
		$mode, $null, $oid = $meta -split ' '
		$map[$p] = @{ type = switch ($mode) { '120000' { 'link' } '160000' { 'gitlink' } default { 'file' } }; id = $oid }
	}
	if ($LASTEXITCODE) { throw "cannot read tree $rev" }
	$map
}
# Types the live entry may have for a HEAD entry. Without core.symlinks Git
# checks a link out as a file holding its target.
function Types($head) { $head.type; if ($head.type -eq 'link' -and -not $symlinks) { 'file' } }
function MatchesHead($live, $head) { $head -and $live.type -in (Types $head) -and (Same $live $head) }
# A path HEAD does not track cannot be classified; a deleted path or one with
# other bytes (or another link target) is a local edit.
function Classify($live, $head) {
	if (-not $head) { if ($live.type -eq 'absent') { '-' } else { 'unclassified' } }
	elseif (MatchesHead $live $head) { 'behind' }
	elseif ($live.type -eq 'absent' -or $live.type -in (Types $head)) { 'local edit' }
	else { 'type change' }
}

$savedEncoding = [Console]::OutputEncoding
try {
	[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
	$classes = [ordered]@{ 'behind' = 0; 'local edit' = 0; 'type change' = 0; 'unclassified' = 0 }
	$unclassified = [Collections.Generic.SortedSet[string]]::new()
	function Count([string]$path, [string]$class) {
		if ($classes.Contains($class)) { $classes[$class]++ }
		if ($class -eq 'unclassified') { $null = $unclassified.Add($path) }
	}

	# Home checkout and guard state.
	$head = @{}
	$symlinks = $autocrlf = $false
	"git_version=$((ReadGit --version) -replace '^git version ', '')"
	if (Test-Path -LiteralPath $gitDir) {
		'checkout=present'
		$sha = ReadGit --git-dir $gitDir rev-parse --verify -q HEAD
		"head=$(if ($sha) { $sha } else { 'unborn' })"
		$upstream = ReadGit --git-dir $gitDir rev-parse -q --verify '@{upstream}'
		$remotes = @(ReadGit --git-dir $gitDir remote)
		$urls = @(ReadGit --git-dir $gitDir config --get-regexp '^remote\..*\.url$' | ForEach-Object { ($_ -split ' ', 2)[1] })
		"upstream=$(if ($upstream) { 'set' } else { 'unset' })"
		"remote_origin=$(if ($remotes -contains 'origin') { 'present' } else { 'absent' })"
		"remote_legacy_origin=$(if ($remotes -contains 'legacy-origin') { 'present' } else { 'absent' })"
		"remote_url_is_this_repo=$(if ($urls -match $originPattern) { 'yes' } else { 'no' })"
		$guarded = -not $upstream -and $remotes -notcontains 'origin' -and $remotes -contains 'legacy-origin'
		"guard=$(if ($guarded) { 'guarded' } else { 'unguarded' })"
		$symlinks = (ReadGit --git-dir $gitDir config --bool core.symlinks) -eq 'true'
		"core_symlinks=$($symlinks.ToString().ToLowerInvariant())"
		$autocrlf = (ReadGit --git-dir $gitDir config --get core.autocrlf) -eq 'true'
		"core_autocrlf=$($autocrlf.ToString().ToLowerInvariant())"
		if ($sha) { $head = Tree $gitDir HEAD }
	}
	else { 'checkout=absent' }

	# Tracked paths that changed against HEAD (gitlinks are reported below).
	foreach ($p in $head.Keys | Sort-Object) {
		$h = $head[$p]
		if ($h.type -eq 'gitlink') { continue }
		$live = Live (Join-Path $Checkout $p)
		if (MatchesHead $live $h) { continue }
		$class = Classify $live $h
		Count $p $class
		"tracked`t$p`t$($h.type)`t$($live.type)`t$($live.id)`t$class"
	}

	# Enrolled roots (shared and Windows streams) against the conversion tip.
	$tipSha = ReadGit --git-dir $TipRepo rev-parse -q --verify "$ConversionTip^{commit}"
	if (-not $tipSha) { throw 'conversion tip not found in -TipRepo' }
	"conversion_tip=$tipSha"
	$tip = Tree $TipRepo $ConversionTip
	$rows = ReadGit --git-dir $TipRepo show "${ConversionTip}:docs/mise-migration/lab/prototype/files.tsv"
	if (-not $rows) { throw 'files.tsv not found at the conversion tip' }
	$states = @{}
	foreach ($row in $rows) {
		$id, $variant, $enrolled, $stream = $row -split "`t"
		if ($variant -notin 'S', 'W') { continue }
		$abs = Join-Path $HomeRoot $enrolled.Substring(2)
		$rel = [IO.Path]::GetRelativePath($Checkout, $abs) -replace '\\', '/'
		$h = if (-not $rel.StartsWith('..')) { $head[$rel] }
		$t = $tip[$stream]
		$live = Live $abs
		$class = Classify $live $h
		$state = if ($live.type -eq 'absent') { 'absent' }
		elseif ($live.type -eq 'file' -and (Same $live $t)) { $class = '-'; 'identical' }
		elseif ($live.type -eq 'link') { 'link' }
		elseif ($class -eq 'behind') { 'behind' }
		else { 'differs' }
		$states[$state]++
		# A tracked root was already counted in the tracked list above.
		if (-not $h -or $class -eq 'behind') { Count $enrolled $class }
		"root`t$id`t$enrolled`t$state`t$($live.type)`t$($live.id)`t$class"
	}
	"root_states=" + (($states.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name):$($_.Value)" }) -join ',')

	# mise version (cache to NUL, offline) and history-store refs.
	$mise = Get-Command mise -CommandType Application -ErrorAction Ignore | Select-Object -First 1
	if ($mise) {
		$env:MISE_CACHE_DIR = 'NUL'; $env:MISE_OFFLINE = '1'
		$v = & $mise.Source --version 2>$null
		"mise_version=$(if ($LASTEXITCODE -eq 0 -and $v) { ($v -split ' ')[0] } else { 'error' })"
	}
	else { 'mise_version=absent' }
	if (Test-Path -LiteralPath $HistoryStore) {
		'history_store=present'
		ReadGit --git-dir $HistoryStore for-each-ref --format='%(objectname)%09%(refname)' | ForEach-Object { "history_ref`t$_" }
	}
	else { 'history_store=absent' }

	if (Get-Command Get-ScheduledTask -ErrorAction Ignore) {
		$tasks = @(Get-ScheduledTask | Where-Object TaskPath -Like '\mise\*')
		"mise_tasks=$($tasks.Count)"
		$tasks | ForEach-Object { "task`t$($_.TaskPath)$($_.TaskName)`t$($_.State)" }
	}
	else { 'mise_tasks=unavailable' }

	foreach ($p in $localInputs) { "local_input`t~/$p`t$(if (Test-Path -LiteralPath (Join-Path $HomeRoot $p)) { 'present' } else { 'absent' })" }

	# Submodule worktrees: status reads attributes from the empty tree, so no
	# filter (LFS included) runs and no index is rewritten.
	foreach ($p in $head.Keys | Where-Object { $head[$_].type -eq 'gitlink' } | Sort-Object) {
		$dir = Join-Path $Checkout $p
		$state = if (-not (Test-Path -LiteralPath (Join-Path $dir '.git'))) { 'uninitialized' }
		else {
			$o = & git -C $dir --attr-source=$emptyTree -c core.fsmonitor=false -c core.attributesFile=NUL status --porcelain --ignore-submodules=none 2>$null
			if ($LASTEXITCODE) { 'error' } elseif ($o) { 'dirty' } else { 'clean' }
		}
		"submodule`t$p`t$state"
	}

	if ($SkipWsl) { 'wsl=skipped' }
	elseif (-not (Get-Command wsl.exe -ErrorAction Ignore)) { 'wsl=unavailable' }
	else {
		$env:WSL_UTF8 = '1'
		foreach ($d in & wsl.exe --list --quiet 2>$null | Where-Object { $_.Trim() }) {
			$o = & wsl.exe -d $d.Trim() --cd ~ --exec timeout 30 env MISE_AUTO_INSTALL=0 git --git-dir=.git config --get-regexp '^remote\..*\.url$' 2>$null
			"wsl`t$($d.Trim())`thome_checkout=$(if ($LASTEXITCODE -eq 0 -and ($o -match $originPattern)) { 'yes' } else { 'no' })"
		}
	}

	$classes.GetEnumerator() | ForEach-Object { "$($_.Key -replace ' ', '_')_count=$($_.Value)" }
	$unclassified | ForEach-Object { "unclassified`t$_" }
	if ($unclassified.Count) { exit 1 }
}
finally {
	[Console]::OutputEncoding = $savedEncoding
	for ($i = 0; $i -lt $envNames.Count; $i++) { [Environment]::SetEnvironmentVariable($envNames[$i], $savedEnv[$i]) }
}
