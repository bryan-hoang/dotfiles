# Verifies the conversion commit at main of a setup.git exchange against the
# plan generated from the approved inventory, the audited-tip tree, and the
# repository-only guard. Read-only for the exchange. Prints key=value results,
# then verify_result=pass|fail with the failed checks, and exits 1 on failure.
# -Kingfisher runs the redacted all-refs scan on a disposable mirror clone.
param(
	[Parameter(Mandatory)][string]$Exchange,
	[Parameter(Mandatory)][string]$Tip,
	[string]$Kingfisher,
	[string]$OutDir
)
$ErrorActionPreference = 'Stop'
$env:MISE_AUTO_INSTALL = '0'
$repo = [IO.Path]::GetFullPath($Exchange)
$p = Join-Path $PSScriptRoot 'prototype'
$inv = Join-Path $PSScriptRoot '..\matrices\10-approved-enrollment-inventory.md'
$workspace = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
function G { $o = & git -C $repo @args; if ($LASTEXITCODE) { throw "git $args failed" }; $o }
$failed = [Collections.Generic.List[string]]::new()
function Say([string]$k, $v) { "$k=$v" }
# Check: prints the value and records a failure unless it equals the expectation.
function Check([string]$k, $v, $want) { "$k=$v"; if ("$v" -ne "$want") { $failed.Add($k) } }
function Tree([string]$rev) {
	$h = @{}
	foreach ($l in (G ls-tree -r --full-tree $rev)) { $meta, $path = $l -split "`t", 2; $m, $null, $o = $meta -split ' '; $h[$path] = "$m $o" }
	$h
}
function Block([string]$tag) {
	$s = [array]::IndexOf($lines, "<!-- ${tag}:start -->"); $e = [array]::IndexOf($lines, "<!-- ${tag}:end -->")
	if ($s -lt 0 -or $e -lt $s) { throw "block not found: $tag" }
	@($lines[($s + 1)..($e - 1)] | Where-Object { $_ -and $_ -notmatch '^```' })
}
$lines = Get-Content -LiteralPath $inv
function BlobId([string]$text) {
	$b = [Text.Encoding]::UTF8.GetBytes($text)
	$h = [Security.Cryptography.SHA1]::HashData([byte[]]([Text.Encoding]::ASCII.GetBytes("blob $($b.Length)`0") + $b))
	-join ($h | ForEach-Object { $_.ToString('x2') })
}

# Repository-only guard: no declaration may source a setup-root legacy path, a
# planning path below /docs, or another repository-only root file such as
# /AGENTS.md or /GLOSSARY.md. Anchored at the setup-repository root, so
# config/dotfiles/... passes. Returns the offending source values.
function Guard([string]$toml, [string[]]$rootFiles) {
	foreach ($m in [regex]::Matches($toml, '(?m)\bsource\s*=\s*["'']([^"'']*)["'']')) {
		$v = $m.Groups[1].Value -replace '\\', '/'
		$rel = $v -replace '^(\./|/)+', ''
		if ($v -match '^~' -or $v -match '^[A-Za-z]:') { continue }
		if ($rel -match '^(\.config|\.local|\.ssh|AppData|src|docs)(/|$)' -or $rootFiles -contains $rel) { $v }
	}
}

$tipFull = (G rev-parse main)
$auditedFull = (G rev-parse "$Tip^{commit}")
Say tip $tipFull
Say audited_tip $auditedFull
$parents = @((G rev-list --parents -n 1 $tipFull) -split ' ' | Select-Object -Skip 1)
Check conversion_parents $parents.Count 1
Check conversion_parent_is_audited_tip $(if ($parents.Count -eq 1 -and $parents[0] -eq $auditedFull) { 'yes' } else { 'no' }) yes

$t = Tree $tipFull
$old = Tree $auditedFull
$files = Get-Content -LiteralPath (Join-Path $p 'files.tsv') | ForEach-Object { $f = $_ -split "`t"; [pscustomobject]@{ Id = $f[0]; Var = $f[1]; Live = $f[2]; Stream = $f[3] } }
$built = @($files | Where-Object Var -NE 'W')
$streamRe = '^(home|config)(@[a-z]+)?/'
$actual = @($t.Keys | Where-Object { $_ -match $streamRe })
Check stream_files $actual.Count $built.Count
Check stream_missing @($built.Stream | Where-Object { -not $t.ContainsKey($_) }).Count 0
Check stream_unexpected @($actual | Where-Object { $built.Stream -notcontains $_ }).Count 0
Check stream_windows_files @($actual | Where-Object { $_ -match '^(home|config)@windows/' }).Count 0
Say stream_by_root (($actual | Group-Object { ($_ -split '/')[0] } | Sort-Object Name | ForEach-Object { "$($_.Name):$($_.Count)" }) -join ',')
Check stream_non_100644 @($actual | Where-Object { ($t[$_] -split ' ')[0] -ne '100644' }).Count 0
$e031 = @($built | Where-Object Id -EQ 'E031')[0].Stream
Check e031_mode ($t[$e031] -split ' ')[0] 100644

# Expected stream bytes: E011 is the generated declaration; a row whose source
# is a regular file at the audited tip takes that blob; every other row is a
# synthetic placeholder for a canonical source a later ticket writes.
$e011 = Join-Path $p 'dotfiles.toml'
$e011Blob = (& git hash-object --no-filters -- $e011)
$fromTip = 0; $synthetic = 0; $authored = 0
$srcRoot = Join-Path $PSScriptRoot 'sources'
$badBytes = @(foreach ($f in $built) {
		if (-not $t.ContainsKey($f.Stream)) { continue }
		$rel = $f.Live.Substring(2)
		$src = Join-Path $srcRoot $rel
		if ($f.Id -eq 'E011') { $want = $e011Blob }
		elseif (Test-Path -LiteralPath $src -PathType Leaf) { $want = (& git hash-object --no-filters -- $src); $authored++ }
		elseif ($old[$rel] -match '^100(644|755) ') { $want = ($old[$rel] -split ' ')[1]; $fromTip++ }
		else { $want = BlobId "# synthetic $($f.Id) $($f.Stream)`n"; $synthetic++ }
		if (($t[$f.Stream] -split ' ')[1] -ne $want) { $f.Id }
	})
Say stream_from_audited_tip $fromTip
Say stream_placeholders $synthetic
Say stream_from_sources $authored
$srcFiles = @(Get-ChildItem -LiteralPath $srcRoot -Recurse -File -Force | ForEach-Object { $_.FullName.Substring($srcRoot.Length + 1) -replace '\\', '/' })
Check sources_unmapped @($srcFiles | Where-Object { $built.Live -notcontains "~/$_" }).Count 0
Check stream_bytes_mismatch $(if ($badBytes.Count) { ($badBytes | Select-Object -Unique) -join ',' } else { 0 }) 0
Check managed_stylua_in_history @($t.Keys | Where-Object { $_ -match '/\.config/nvim/stylua\.toml$' }).Count 0

$roots = Block 'enrollment-roots' | Where-Object { $_ -match '^\|\s*`?E\d{3}`?\s' } | ForEach-Object { $f = @($_.Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim().Trim('`') }); [pscustomobject]@{ Id = $f[0]; Source = $f[1]; Enroll = $f[2]; Variant = $f[5]; Autosave = $f[6] } }
$m = (G show "${tipFull}:.mise-history/manifest.json") -join "`n" | ConvertFrom-Json
Check format_marker (((G show "${tipFull}:.mise-history/format.toml") | Where-Object { $_ -match '^format' }) -join '') 'format = 1'
Check manifest_entries $m.enrollment.Count $roots.Count
$os = @{ S = ''; W = 'windows'; L = 'linux' }
$mm = @(foreach ($r in $roots) {
		$x = @($m.enrollment | Where-Object path -EQ $r.Enroll)
		if ($x.Count -ne 1 -or $x[0].autosave -ne ($r.Autosave -eq 'on') -or $x[0].encrypt -or ((@($x[0].variants | ForEach-Object { $_.os }) -join ',') -ne $os[$r.Variant])) { $r.Id }
	})
Check manifest_row_mismatches $(if ($mm.Count) { $mm -join ',' } else { 0 }) 0
Check manifest_duplicate_paths @($m.enrollment.path | Group-Object | Where-Object Count -GT 1).Count 0
Check manifest_recipients $m.recipients.Count 0
Check manifest_exclude ($m.exclude -join ',') '~/.config/nvim/stylua.toml'

# Legacy partition: the approved removed count plus the deferred X11 links
# leave the tip; every other audited-tip entry stays, unchanged except the
# approved rewrites below and executables normalized to 100644.
$approved = @($lines | Where-Object { $_ -match '^\|\s*Enrolled-source / managed / repository-only / removed' })[0]
$approvedRemoved = [int](($approved -split '\|')[2].Trim() -split '\s*/\s*')[3]
$x11Links = Block 'deferred-x11-links'
$removals = @('.gitmodules') + @($old.Keys | Where-Object { $old[$_] -like '160000 *' }) + (Block 'removed-legacy-paths') + $x11Links
Say legacy_entries $old.Count
Check legacy_removals_unknown @($removals | Where-Object { -not $old.ContainsKey($_) }).Count 0
Check legacy_removed ($removals.Count - $x11Links.Count) $approvedRemoved
Check legacy_x11_links_removed $x11Links.Count 10
Check legacy_removed_still_present @($removals | Where-Object { $t.ContainsKey($_) }).Count 0
$kept = @($old.Keys | Where-Object { $removals -notcontains $_ })
Say legacy_kept $kept.Count
Check legacy_kept_missing @($kept | Where-Object { -not $t.ContainsKey($_) }).Count 0
# Approved content rewrites: the workspace README and the reviewed bytes in
# lab/rewrites/<path>.rewrite. Each must equal its workspace bytes, and a
# rewrite counts as changed only where it differs from the audited tip.
$rewriteRoot = Join-Path $PSScriptRoot 'rewrites'
$rewrites = [ordered]@{ '.config/shell/functions.sh' = $null; 'README.md' = Join-Path $workspace 'README.md'; 'package.json' = $null; 'pnpm-lock.yaml' = $null }
# Private-data sanitization (#389): the removed values never appear here.
foreach ($k in @(
		'.config/X11/xresources', '.config/bspwm/bspwmrc', '.config/git/distributive.gitconfig', '.local/bin/print-git-email-symbol', '.config/clipcat/clipcat-menu.toml', '.config/clipcat/clipcatctl.toml', '.config/clipcat/clipcatd.toml'
		'.config/emscripten/config', '.config/himalaya/config.toml', '.config/i3/config', '.config/i3status-rust/config.toml'
		'.config/meli/config.toml', '.config/pam-gnupg', '.config/redshift.conf', '.config/rust-motd/config.toml'
		'.config/spotify-tui/client.yml', '.config/spotifyd/spotifyd.conf', '.config/systemd/user/emacs.service'
		'.config/systemd/user/gpg-agent-browser.socket', '.config/systemd/user/gpg-agent-extra.socket'
		'.config/systemd/user/gpg-agent-ssh.socket', '.config/systemd/user/gpg-agent.socket'
		'.config/systemd/user/lemonade.service', '.config/systemd/user/tmux.service', '.local/bin/run-as-cron'
	)) { $rewrites[$k] = $null }
foreach ($k in @($rewrites.Keys)) { if (-not $rewrites[$k]) { $rewrites[$k] = Join-Path $rewriteRoot "$k.rewrite" } }
$staged = @(Get-ChildItem -LiteralPath $rewriteRoot -Recurse -File -Force | ForEach-Object { $_.FullName.Substring($rewriteRoot.Length + 1) -replace '\\', '/' -replace '\.rewrite$', '' })
Check rewrites_unexpected_files @($staged | Where-Object { -not $rewrites.Contains($_) }).Count 0
$rewriteBlobs = @{}
foreach ($k in $rewrites.Keys) { $rewriteBlobs[$k] = (& git hash-object --no-filters -- $rewrites[$k]) }
Check rewrites_not_matching_workspace @($rewrites.Keys | Where-Object { ($t[$_] -split ' ')[1] -ne $rewriteBlobs[$_] }).Count 0
$expectedChanged = @($rewrites.Keys | Where-Object { $rewriteBlobs[$_] -ne ($old[$_] -split ' ')[1] } | Sort-Object)
$contentChanged = @($kept | Where-Object { $t[$_] -and ($t[$_] -split ' ')[1] -ne ($old[$_] -split ' ')[1] } | Sort-Object)
Say legacy_kept_content_changed_expected ($expectedChanged -join ',')
Check legacy_kept_content_changed ($contentChanged -join ',') ($expectedChanged -join ',')
$modeChanged = @($kept | Where-Object { $t[$_] -and ($t[$_] -split ' ')[0] -ne ($old[$_] -split ' ')[0] })
Say legacy_kept_mode_changed $modeChanged.Count
Check legacy_mode_changes_not_exec_to_regular @($modeChanged | Where-Object { "$(($old[$_] -split ' ')[0])>$(($t[$_] -split ' ')[0])" -ne '100755>100644' }).Count 0
Check legacy_kept_executable @($kept | Where-Object { $t[$_] -like '100755 *' }).Count 0
Check gitmodules_in_tip $(if ($t.ContainsKey('.gitmodules')) { 'yes' } else { 'no' }) no
Check gitlinks_in_tip @($t.Values | Where-Object { $_ -like '160000 *' }).Count 0
Say repository_only_in_tip @($t.Keys | Where-Object { $_ -notmatch $streamRe -and $_ -notlike '.mise-history/*' }).Count

$rootFiles = @($t.Keys | Where-Object { $_ -notmatch '/' -and $_ -notmatch $streamRe }) + 'AGENTS.md', 'GLOSSARY.md'
$decl = @($actual | Where-Object { $_ -match '^config(@[a-z]+)?/.*\.toml$' })
$violations = @(foreach ($d in $decl) { Guard ((G cat-file blob ($t[$d] -split ' ')[1]) -join "`n") $rootFiles })
Say repository_only_guard_declarations $decl.Count
Check repository_only_guard_violations $violations.Count 0
$bad = "[dotfiles]`n`"~/.x`" = { source = `".config/git/config`" }`n`"~/.y`" = { source = `"README.md`" }`n`"~/.z`" = { source = `"/docs/agents/domain.md`" }`n`"~/.w`" = { source = `"./AGENTS.md`" }`n`"~/.v`" = { source = `"GLOSSARY.md`" }`n"
$good = "[dotfiles]`n`"~/.x`" = { source = `"config/dotfiles/.config/git/config`" }`n`"~/.y`" = { source = `"config/dotfiles/docs/x`" }`n"
Check repository_only_guard_negative_control "$(@(Guard $bad $rootFiles).Count),$(@(Guard $good $rootFiles).Count)" '5,0'

$x11 = Block 'deferred-x11-sources'
$e011Text = [IO.File]::ReadAllText($e011)
Check x11_sources_repository_only_expected_content @($x11 | Where-Object { $t[$_] -and ($t[$_] -split ' ')[1] -eq $(if ($rewrites.Contains($_)) { $rewriteBlobs[$_] } else { ($old[$_] -split ' ')[1] }) }).Count $x11.Count
Check x11_in_manifest @($m.enrollment.path | Where-Object { $p2 = $_; @($x11 | Where-Object { $p2 -like "*/$_" }).Count }).Count 0
Check x11_in_e011 @(@($x11) + 'xresources', 'dunst', 'dracula/gtk', 'dracula/rofi' | Where-Object { $e011Text.Contains($_) }).Count 0

# Forbidden private-data classes (#389): any hit anywhere in the built tip
# fails. Rows carry path, class, and line count only, never values.
$forbidden = @(& (Join-Path $PSScriptRoot 'forbidden-scan.ps1') -Repo $repo -Rev $tipFull)
foreach ($h in $forbidden) { Say forbidden_hit ($h -replace "`t", ':') }
Check forbidden_hits $forbidden.Count 0
$probe = @(('a@corp-mail' + '.test'), ('signing' + 'key = 0123456789' + 'ABCDEF'), ('pass' + 'word = s3cr3tvalue'), ('Host' + 'Name 10.1' + '.2.3'), 'personal bryan@bryanhoang.dev', ('pass' + 'word = "password"'))
Check forbidden_negative_control ((& (Join-Path $PSScriptRoot 'forbidden-scan.ps1') -Text $probe) -join ',') 'work-identity,key-identifier,credential,private-endpoint,,'

if ($Kingfisher) {
	if (-not $OutDir) { throw '-OutDir is required with -Kingfisher' }
	New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
	Check kingfisher_exe_sha256 (Get-FileHash -LiteralPath $Kingfisher -Algorithm SHA256).Hash.ToLower() '7c4d9566294188ef67856ba40c4497b65f3e481c5f1023f2659cb599c43d11c6'
	$scanRoot = Join-Path $env:LOCALAPPDATA 'Temp\opencode'
	$mirror = Join-Path $scanRoot "kingfisher-audit-$([guid]::NewGuid())"
	try {
		& git clone -q --mirror --no-local $repo $mirror
		if ($LASTEXITCODE) { throw 'mirror clone failed' }
		$commits = [int](& git -C $mirror rev-list --all --count)
		& $Kingfisher scan $mirror --git-history full --redact --no-validate --no-update-check --no-rule-cache --quiet --format json --output (Join-Path $OutDir 'kingfisher.json') *> (Join-Path $OutDir 'kingfisher.terminal.txt')
		$kfExit = $LASTEXITCODE
		Check kingfisher_exit $kfExit 0
		$kj = Get-Content -LiteralPath (Join-Path $OutDir 'kingfisher.json') -Raw | ConvertFrom-Json
		$audit = @($kj.audit.repositories)
		Check kingfisher_findings @($kj.findings).Count 0
		Check kingfisher_repositories $audit.Count 1
		Check kingfisher_scope "$($audit[0].source),$($audit[0].scan.status),$($audit[0].git.scope)" 'local,completed,all_fetched_git_objects'
		Check kingfisher_commits_covered $(if ([int]$audit[0].git.fetched_commit_count -eq $commits) { 'yes' } else { 'no' }) yes
		Say kingfisher_commits $commits
	}
	finally {
		$full = [IO.Path]::GetFullPath($mirror)
		if ($full.StartsWith($scanRoot + '\kingfisher-audit-') -and (Test-Path -LiteralPath $full) -and -not (Get-Item -LiteralPath $full -Force).LinkType) {
			Remove-Item -LiteralPath $full -Recurse -Force
		}
	}
}

"verify_result=$(if ($failed.Count) { 'fail' } else { 'pass' })"
if ($failed.Count) { "verify_failed=$($failed -join ',')"; exit 1 }
