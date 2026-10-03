# Host-side lab for work-baseline.ps1. Builds a disposable fake home-root
# checkout of -Legacy from the exchange plus a tip repository holding the
# conversion bundle, runs the baseline on the clean home (expects exit 0), then
# on an altered home (behind file, local edit, replaced link, repointed root,
# unclassifiable root, guard, dirty submodule, history store, local input) and
# asserts classes, exit codes, redaction, and that a hash snapshot of the home
# and tip repository is unchanged by each run. Prints key=value lines; exits 1
# on any failed check. Windows Sandbox media carries no PowerShell 7, so this
# runs on the host under %LOCALAPPDATA%\Temp\opencode with -SkipWsl.
param(
	[Parameter(Mandatory)][string]$Exchange,
	[Parameter(Mandatory)][string]$ConversionBundle,
	[Parameter(Mandatory)][string]$MiseDir,
	[string]$Legacy = '46df470377a5f4d45e98c69223263bcf85434d34',
	[string]$LabRoot = (Join-Path $env:LOCALAPPDATA ('Temp\opencode\work-baseline-lab-' + (Get-Date -Format 'yyyyMMddHHmmss')))
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$env:MISE_AUTO_INSTALL = '0'
$env:GIT_TERMINAL_PROMPT = '0'
foreach ($n in 'GITHUB_TOKEN', 'GH_TOKEN', 'GITHUB_API_TOKEN', 'MISE_GITHUB_TOKEN') { Remove-Item -LiteralPath "Env:$n" -ErrorAction Ignore }
$disposable = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Temp\opencode'))
$lab = [IO.Path]::GetFullPath($LabRoot)
if (-not $lab.StartsWith($disposable + '\') -or (Test-Path -LiteralPath $lab)) { throw "lab root must be new and inside $disposable" }
$homeDir = Join-Path $lab 'home'
$tipRepo = Join-Path $lab 'tip.git'
$out = Join-Path $lab 'out'
$null = New-Item -ItemType Directory -Path $out
# Setup Git ignores the host's global hooks and filters; the baseline runs see
# the fake home's own Git configuration through HOME.
$env:GIT_CONFIG_GLOBAL = Join-Path $lab 'gitconfig'
$env:GIT_CONFIG_NOSYSTEM = '1'
[IO.File]::WriteAllText($env:GIT_CONFIG_GLOBAL, "[gc]`n`tauto = 0`n[maintenance]`n`tauto = false`n")
$failed = [Collections.Generic.List[string]]::new()
function Check([string]$name, [bool]$ok) { "$name=$(if ($ok) { 'pass' } else { 'FAIL' })"; if (-not $ok) { $failed.Add($name) } }

git init -q --bare $tipRepo
git --git-dir $tipRepo fetch -q (Join-Path $Exchange 'setup.git') main:refs/heads/legacy-main
git --git-dir $tipRepo fetch -q $ConversionBundle main:refs/heads/conversion
$tip = git --git-dir $tipRepo rev-parse conversion
"tip=$tip"
git clone -q -c core.symlinks=true --no-local (Join-Path $Exchange 'setup.git') $homeDir
git -C $homeDir reset -q --hard $Legacy

function Snapshot {
	Get-ChildItem -LiteralPath $homeDir, $tipRepo -Recurse -Force | Sort-Object FullName | ForEach-Object {
		# Content only: NTFS reports directory times lazily through enumeration.
		$h = if ($_.LinkTarget) { 'link:' + $_.LinkTarget } elseif ($_.PSIsContainer) { 'dir' } else { (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
		"$($_.FullName)`t$h"
	}
}
function Baseline([string]$name) {
	$before = Snapshot
	$file = Join-Path $out "$name.txt"
	$saved = $env:PATH, $env:HOME, $env:GIT_CONFIG_GLOBAL, $env:GIT_CONFIG_NOSYSTEM
	$PSNativeCommandUseErrorActionPreference = $false
	try {
		$env:PATH = "$MiseDir;$env:PATH"; $env:HOME = $homeDir
		$env:GIT_CONFIG_GLOBAL = $null; $env:GIT_CONFIG_NOSYSTEM = $null
		& pwsh -NoProfile -NonInteractive -File (Join-Path $PSScriptRoot 'work-baseline.ps1') -HomeRoot $homeDir -TipRepo $tipRepo -ConversionTip $tip -SkipWsl *> $file
		$code = $LASTEXITCODE
	}
	catch { $code = 'threw' }
	finally { $env:PATH, $env:HOME, $env:GIT_CONFIG_GLOBAL, $env:GIT_CONFIG_NOSYSTEM = $saved }
	$after = Snapshot
	$diff = @(Compare-Object $before $after)
	"${name}_exit=$code"
	"${name}_snapshot_entries=$($before.Count)"
	Check "${name}_writes_nothing" ($diff.Count -eq 0)
	$diff | Select-Object -First 10 | ForEach-Object { "  changed $($_.SideIndicator) $($_.InputObject.Replace($lab, '<lab>'))" }
	$lines = [IO.File]::ReadAllLines($file)
	$lines | ForEach-Object { "  $_" }
	, $lines
}
function Row([string[]]$lines, [string]$prefix, [string]$path) { $lines | Where-Object { $_ -like "$prefix`t*" -and ($_ -split "`t") -contains $path } | Select-Object -First 1 }
function Class([string]$row) { ($row -split "`t")[-1] }
function State([string]$row) { ($row -split "`t")[3] }

# Clean home at the legacy tip: E063 and E177 changed in be51989, so they are behind.
$r = Baseline 'clean'; $clean = $r[-1]; $r[0..($r.Count - 2)]
Check 'clean_exit_0' ($r -contains 'clean_exit=0')
Check 'clean_e063_behind' ((Class (Row $clean 'root' '~/.config/hk/config.pkl')) -eq 'behind')
Check 'clean_e177_behind' ((Class (Row $clean 'root' '~/.typos.toml')) -eq 'behind')
Check 'clean_no_tracked_changes' (@($clean | Where-Object { $_ -like "tracked`t*" }).Count -eq 0)
Check 'clean_unclassified_0' ($clean -contains 'unclassified_count=0')
Check 'clean_unguarded' ($clean -contains 'guard=unguarded')
Check 'clean_mise_version' ($clean -contains 'mise_version=2026.10.0')

# Alterations.
$marker = 'lab-private-value-377'
$edit = '.config/git/alias.gitconfig'
[IO.File]::AppendAllText((Join-Path $homeDir $edit), "# $marker`n")
$link, $retarget = (git -C $homeDir ls-tree -r --full-tree HEAD | Where-Object { $_ -like '120000 *' } | Select-Object -First 2) -replace '^.*\t', ''
$linkPath = Join-Path $homeDir $link
if (-not (Get-Item -LiteralPath $linkPath -Force).LinkTarget) { throw "symlinks are not enabled for the lab checkout: $link" }
Remove-Item -LiteralPath $linkPath -Force
[IO.File]::WriteAllText($linkPath, "$marker`n")
# A link pointing somewhere else is still a link: a local edit.
Remove-Item -LiteralPath (Join-Path $homeDir $retarget) -Force
$null = New-Item -ItemType SymbolicLink -Path (Join-Path $homeDir $retarget) -Target $marker
# CRLF bytes under core.autocrlf=true are what Git itself checks out: no change.
$crlf = '.typos.toml'
$crlfPath = Join-Path $homeDir $crlf
[IO.File]::WriteAllText($crlfPath, ([IO.File]::ReadAllText($crlfPath) -replace "`n", "`r`n"))
git -C $homeDir config core.autocrlf true
$repoint = '.config/git/attributes'
Remove-Item -LiteralPath (Join-Path $homeDir $repoint) -Force
$null = New-Item -ItemType SymbolicLink -Path (Join-Path $homeDir $repoint) -Target 'alias.gitconfig'
$unknown = '.config/mise/config.toml'
$null = New-Item -ItemType Directory -Path (Join-Path $homeDir '.config/mise') -Force
[IO.File]::WriteAllText((Join-Path $homeDir $unknown), "# $marker`n")
[IO.File]::WriteAllText((Join-Path $homeDir '.config/mise/config.local.toml'), "token = `"$marker`"`n")
git -C $homeDir remote rename origin legacy-origin
git -C $homeDir branch -q --unset-upstream
$sub = (git -C $homeDir ls-tree -r --full-tree HEAD | Where-Object { $_ -like '160000 *' } | Select-Object -First 1) -replace '^.*\t', ''
git init -q (Join-Path $homeDir $sub)
[IO.File]::WriteAllText((Join-Path $homeDir "$sub/untracked.txt"), "$marker`n")
$store = Join-Path $homeDir '.local/state/mise/history/repo.git'
git init -q --bare $store
git --git-dir $store fetch -q $tipRepo conversion:refs/heads/main

$r = Baseline 'altered'; $alt = $r[-1]; $r[0..($r.Count - 2)]
Check 'altered_exit_nonzero' ($r -contains 'altered_exit=1')
Check 'altered_behind' ((Class (Row $alt 'root' '~/.config/hk/config.pkl')) -eq 'behind')
Check 'altered_local_edit' ((Class (Row $alt 'root' "~/$edit")) -eq 'local edit')
Check 'altered_local_edit_tracked' ((Class (Row $alt 'tracked' $edit)) -eq 'local edit')
Check 'altered_replaced_link' ((Class (Row $alt 'tracked' $link)) -eq 'type change')
Check 'altered_retargeted_link' ((Class (Row $alt 'tracked' $retarget)) -eq 'local edit')
Check 'altered_crlf_not_tracked' ($null -eq (Row $alt 'tracked' $crlf))
Check 'altered_crlf_root_behind' ((Class (Row $alt 'root' "~/$crlf")) -eq 'behind')
Check 'altered_repointed_root_state' ((State (Row $alt 'root' "~/$repoint")) -eq 'link')
Check 'altered_repointed_root' ((Class (Row $alt 'root' "~/$repoint")) -eq 'type change')
Check 'altered_unclassified_root' ((Class (Row $alt 'root' "~/$unknown")) -eq 'unclassified')
Check 'altered_unclassified_listed' ($alt -contains "unclassified`t~/$unknown")
Check 'altered_unclassified_count' ($alt -contains 'unclassified_count=1')
Check 'altered_guarded' ($alt -contains 'guard=guarded')
Check 'altered_submodule_dirty' ($alt -contains "submodule`t$sub`tdirty")
Check 'altered_history_ref' ($alt -contains "history_ref`t$tip`trefs/heads/main")
Check 'altered_local_input_present' ($alt -contains "local_input`t~/.config/mise/config.local.toml`tpresent")
Check 'altered_local_input_absent' ($alt -contains "local_input`t~/.config/git/machine.gitconfig`tabsent")
Check 'output_has_no_values' (-not (Select-String -Path (Join-Path $out '*.txt') -SimpleMatch $marker -Quiet))
Check 'output_has_no_lab_path' (-not (Select-String -Path (Join-Path $out '*.txt') -SimpleMatch $lab -Quiet))

"failed=$($failed.Count)"
$full = [IO.Path]::GetFullPath($lab)
if ($full.StartsWith($disposable + '\') -and -not (Get-Item -LiteralPath $full).LinkTarget) { Remove-Item -LiteralPath $full -Recurse -Force }
exit [int]($failed.Count -gt 0)
