# Windows application units (#375) run for Windows Sandbox (Windows
# PowerShell 5.1, ASCII only; the module runs in the staged PowerShell 7 from
# C:\lab-in\bin\pwsh). Adopts the conversion from the exchange copy, delivers
# the Windows sources the tip does not carry (W rows from audited-tip blobs,
# E161 to E163 from C:\lab-in\sources) and saves them into history, then
# drives every unit in the module's path map. Applications are stand-ins:
# whoami.exe copied under each command name, Terminal package folders created
# when absent. Writes key=value results and logs to C:\lab-out; pass=yes only
# when every check holds.
$ErrorActionPreference = 'Stop'
$in = 'C:\lab-in'
$out = 'C:\lab-out'
$lab = 'C:\lab'
$results = Join-Path $out 'sandbox-windows-units.txt'
$script:fails = @()
function Say([string]$k, [string]$v) { Add-Content -LiteralPath $results -Value "$k=$v" -Encoding ASCII }
function Check([string]$k, $actual, $expected) {
	Say $k "$actual"
	if ("$actual" -ne "$expected") { $script:fails += $k }
}
function Run([string]$name, [string]$exe, [string[]]$argv) {
	$ErrorActionPreference = 'Continue'
	$o = & $exe @argv 2>&1 | ForEach-Object { "$_" }
	$code = $LASTEXITCODE
	[IO.File]::WriteAllText((Join-Path $out "$name.log"), (($o -join "`n") + "`n"))
	Say "${name}_exit" $code
	$code
}
function Log([string]$name) { [IO.File]::ReadAllText((Join-Path $out "$name.log")) }
function Live([string]$tilde) { Join-Path $env:USERPROFILE ($tilde.Substring(2) -replace '/', '\') }
function Hash([string]$p) { if (Test-Path -LiteralPath $p -PathType Leaf) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash } else { 'missing' } }
function LinkOf([string]$p) {
	$i = Get-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
	if (-not $i) { return 'absent' }
	if (-not $i.LinkType) { return 'plain' }
	"$($i.LinkType)->$(@($i.Target)[0])"
}
# One fresh PowerShell 7 process per module command; objects print as name=value lines.
function Mod([string]$name, [string]$cmd) {
	$fmt = ' | ForEach-Object { ($_.PSObject.Properties | ForEach-Object { $_.Name + ''='' + $_.Value }) -join '' | '' }'
	Run $name $pwsh @('-NoProfile', '-NonInteractive', '-Command', ("Import-Module '$mod'; " + $cmd + $fmt))
}
function Rows([string]$log, [string]$pattern) { [regex]::Matches((Log $log), $pattern).Count }
function Flags([string[]]$lines) { [IO.File]::WriteAllText($flags, ((@('# lab-marker-375-local', '[vars.windows_applications]') + $lines) -join "`n") + "`n", $lf) }
$lf = New-Object Text.UTF8Encoding $false
try {
	Start-Transcript -LiteralPath (Join-Path $out 'transcript.txt') | Out-Null
	New-Item -ItemType Directory -Path (Join-Path $lab 'bin'), (Join-Path $lab 'stub'), (Join-Path $lab 'login-stub'), (Join-Path $lab 'aside') -Force | Out-Null
	$p1 = Start-Process -FilePath 'C:\fixture-media\vc_redist.x64.exe' -ArgumentList '/install', '/quiet', '/norestart' -Wait -PassThru
	$p2 = Start-Process -FilePath 'C:\fixture-media\Git-2.55.0.3-64-bit.exe' -ArgumentList '/VERYSILENT', '/NORESTART', '/NOCANCEL', '/SP-', '/SUPPRESSMSGBOXES' -Wait -PassThru
	Say 'installs_exit' "$($p1.ExitCode),$($p2.ExitCode)"
	$git = 'C:\Program Files\Git\cmd\git.exe'
	Copy-Item -LiteralPath (Join-Path $in 'bin\mise.exe'), (Join-Path $in 'bin\mise-shim.exe') -Destination (Join-Path $lab 'bin')
	if (-not (Test-Path -LiteralPath (Join-Path $in 'bin\pwsh\pwsh.exe'))) { throw 'PowerShell 7 media is not staged (windows-media-pwsh-<version>)' }
	Copy-Item -LiteralPath (Join-Path $in 'bin\pwsh') -Destination (Join-Path $lab 'pwsh') -Recurse
	Copy-Item -LiteralPath (Join-Path $in 'exchange') -Destination (Join-Path $lab 'exchange') -Recurse
	$mise = Join-Path $lab 'bin\mise.exe'
	$pwsh = Join-Path $lab 'pwsh\pwsh.exe'
	$env:PATH = "$lab\bin;C:\Program Files\Git\cmd;$env:PATH"
	$env:MISE_HISTORY_SYNC = 'manual'
	$env:MISE_AUTO_INSTALL = '0'
	$env:GIT_CONFIG_NOSYSTEM = '1'
	$env:GIT_CONFIG_GLOBAL = Join-Path $lab 'gitconfig'
	$env:GIT_TERMINAL_PROMPT = '0'
	Set-Location -LiteralPath $lab

	$ex = 'C:/lab/exchange'
	$gh = 'https://github.com'
	$cfg = @('[protocol]', "`tallow = never", '[protocol "file"]', "`tallow = always", '[user]', "`tname = Lab", "`temail = lab@localhost")
	$repos = @(Get-Content -LiteralPath (Join-Path $in 'repos.txt') | Where-Object { $_.Trim() })
	foreach ($repo in $repos) {
		$cfg += "[url `"$ex/mirrors/$repo.git`"]", "`tinsteadOf = $gh/$repo"
		$cfg += "[url `"$ex/mirrors/$repo.git`"]", "`tinsteadOf = $gh/$repo.git"
	}
	foreach ($origin in 'https://github.com/bryan-hoang/dotfiles', 'ssh://git@github.com/bryan-hoang/dotfiles') {
		$cfg += "[url `"$ex/setup.git`"]", "`tinsteadOf = $origin"
	}
	[IO.File]::WriteAllText($env:GIT_CONFIG_GLOBAL, (($cfg -join "`n") + "`n"), $lf)
	Run 'version' $mise @('--version') | Out-Null
	$seed = (& $git -C "$ex/setup.git" rev-parse main)
	$tip = (& $git -C "$ex/setup.git" rev-parse "$seed^")
	Say 'seed_tip' $seed
	Say 'audited_tip' $tip
	Check 'adopt_exit' (Run 'adopt' $mise @('bootstrap', '--adopt', 'https://github.com/bryan-hoang/dotfiles', '--yes', '--skip', 'tools')) 0

	# Round-4: E011 renders the Windows Herdr output from the E101 template.
	$herdr = Join-Path $env:APPDATA 'herdr\config.toml'
	$ht = if (Test-Path -LiteralPath $herdr -PathType Leaf) { [IO.File]::ReadAllText($herdr) } else { '' }
	Check 'herdr_rendered' ($ht -ne '') 'True'
	Check 'herdr_default_shell_pwsh' ($ht -match '(?m)^default_shell = "pwsh"\r?$') 'True'
	Check 'herdr_kitty_graphics_off' ($ht -match '(?m)^kitty_graphics = false\r?$') 'True'
	Check 'herdr_template_syntax_left' ($ht -match '\{[{%]') 'False'

	# Windows sources: W rows from audited-tip blobs, E161 to E163 from lab-in.
	$saved = @()
	foreach ($rel in '.config/mintty/config', '.config/pwsh/Microsoft.PowerShell_profile.ps1', '.config/pwsh/Initialize-Functions.ps1', '.config/pwsh/Initialize-Environment.ps1', '.config/rio/config.toml', '.config/alacritty/alacritty.common.toml', '.config/windows/wind-term-settings.json') {
		$dest = Live "~/$rel"
		New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
		Start-Process -FilePath $git -ArgumentList @('-C', "$ex/setup.git", 'cat-file', 'blob', "${tip}:$rel") -RedirectStandardOutput $dest -NoNewWindow -Wait | Out-Null
		Check "source_exact_$rel" ((& $git hash-object --no-filters -- $dest) -eq (& $git -C "$ex/setup.git" rev-parse "${tip}:$rel")) 'True'
		$saved += $dest
	}
	$authored = @{
		mod  = '.config/mise/dotfiles/.config/windows/WindowsApplications.psm1'
		e162 = '.config/mise/dotfiles/AppData/Roaming/alacritty/alacritty.toml'
		e163 = '.config/mise/dotfiles/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/start-atuin-daemon.vbs'
	}
	foreach ($k in 'mod', 'e162', 'e163') {
		$dest = Live "~/$($authored[$k])"
		New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
		Copy-Item -LiteralPath (Join-Path (Join-Path $in 'sources') ($authored[$k] -replace '/', '\')) -Destination $dest
		$saved += $dest
	}
	$mod = Live "~/$($authored.mod)"
	$e162 = Live "~/$($authored.e162)"
	$e163 = Live "~/$($authored.e163)"
	Check 'save_windows_sources_exit' (Run 'save_windows' $mise (@('dot', 'save', '--description', 'Windows sources') + $saved)) 0
	$H = Live '~/.local/state/mise/history/repo.git'
	foreach ($k in 'e162', 'e163') {
		$stream = 'config@windows/' + $authored[$k].Substring('.config/mise/'.Length)
		Check "history_${k}_blob_matches_source" ((& $git -C $H rev-parse "main:$stream") -eq (& $git hash-object --no-filters -- (Live "~/$($authored[$k])"))) 'True'
	}

	# Review codes (PUBLIC): no literal user path or machine identifier in E162/E163.
	foreach ($k in 'e162', 'e163') {
		$t = [IO.File]::ReadAllText((Live "~/$($authored[$k])"))
		Check "${k}_private_literals" ([regex]::Matches($t, '(?i)C:\\Users|bryan|@|https?://|\\\\[a-z0-9]').Count) 0
		Check "${k}_crlf" $t.Contains("`r") 'False'
	}

	# Stand-ins: each application command is whoami.exe under its name; atuin
	# only on the persistent login PATH; Terminal package folders when absent.
	foreach ($c in 'alacritty', 'bat', 'espanso', 'harper-ls', 'hx', 'ncspot', 'rio', 'rtk', 'topgrade') {
		Copy-Item -LiteralPath "$env:WINDIR\System32\whoami.exe" -Destination (Join-Path $lab "stub\$c.exe")
	}
	$env:PATH = "$lab\stub;$env:PATH"
	Copy-Item -LiteralPath "$env:WINDIR\System32\whoami.exe" -Destination (Join-Path $lab 'login-stub\atuin.exe')
	foreach ($pkg in 'Microsoft.WindowsTerminal_8wekyb3d8bbwe', 'Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe') {
		$pd = Join-Path $env:LOCALAPPDATA "Packages\$pkg"
		Say "terminal_package_real_$pkg" (Test-Path -LiteralPath $pd)
		New-Item -ItemType Directory -Path $pd -Force | Out-Null
	}
	# ncspot's source is excluded local authority.
	New-Item -ItemType Directory -Path (Live '~/.config/ncspot') -Force | Out-Null
	[IO.File]::WriteAllText((Live '~/.config/ncspot/config.toml'), "# lab-marker-375-local`n", $lf)

	$flags = Live '~/.config/mise/config.windows.local.toml'
	$optional = 'alacritty', 'atuin_daemon', 'bat', 'espanso', 'harper', 'helix', 'ncspot', 'rio', 'rtk', 'terminal_preview', 'terminal_stable', 'topgrade'
	$unflagged = 'espanso', 'harper'
	Flags @($optional | Where-Object { $_ -ne 'espanso' } | ForEach-Object { "$_ = $(if ($_ -in $unflagged) { 'false' } else { 'true' })" })
	Mod 'pathmap' 'Get-WindowsApplicationsPathMap' | Out-Null
	Check 'pathmap_units' (@([regex]::Matches((Log 'pathmap'), 'Unit=(\w+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique) -join ',') 'alacritty,atuin_daemon,base,bat,espanso,harper,helix,ncspot,rio,rtk,terminal_preview,terminal_stable,topgrade'
	Check 'pathmap_rows' (Rows 'pathmap' 'Unit=') 20

	$d = @{
		profile   = (& $pwsh -NoProfile -Command '$PROFILE.CurrentUserCurrentHost')
		mintty    = Join-Path $env:APPDATA 'mintty'
		alacritty = Join-Path $env:APPDATA 'alacritty\alacritty.toml'
		atuin     = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\start-atuin-daemon.vbs'
		bat       = Join-Path $env:APPDATA 'bat'
		espanso   = Join-Path $env:APPDATA 'espanso'
		harper    = Join-Path $env:APPDATA 'harper-ls\dictionary.txt'
		helix     = Join-Path $env:APPDATA 'helix'
		ncspot    = Join-Path $env:APPDATA 'ncspot'
		riotheme  = Live '~/.config/rio/themes/catppuccin-mocha.toml'
		rio       = Join-Path $env:LOCALAPPDATA 'rio'
		rtk       = Join-Path $env:APPDATA 'rtk'
		preview   = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'
		stable    = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
		topgrade  = Join-Path $env:APPDATA 'topgrade.toml'
	}
	$state = Live '~/.local/state/mise/windows-applications'
	$rioRepo = Live '~/src/github.com/catppuccin/rio'
	$alaRepo = Live '~/src/github.com/catppuccin/alacritty'

	# Unflagged units hold plain occupants that apply must leave alone.
	New-Item -ItemType Directory -Path $d.espanso, (Split-Path $d.harper) -Force | Out-Null
	[IO.File]::WriteAllText((Join-Path $d.espanso 'occupant.txt'), "unmanaged`n", $lf)
	[IO.File]::WriteAllText($d.harper, "unmanaged`n", $lf)
	$occ = (Hash (Join-Path $d.espanso 'occupant.txt')) + (Hash $d.harper)

	# atuin_daemon requires atuin on the persistent login PATH, not the process PATH.
	Copy-Item -LiteralPath (Join-Path $lab 'login-stub\atuin.exe') -Destination (Join-Path $lab 'stub\atuin.exe')
	Check 'login_path_missing_exit' (Mod 'login_path_missing' 'Invoke-WindowsApplications apply -Unit atuin_daemon') 1
	Check 'login_path_missing_reported' (Rows 'login_path_missing' 'Unit=atuin_daemon .*missing application atuin on the login PATH') 1
	Check 'login_path_missing_dest' (LinkOf $d.atuin) 'absent'
	Remove-Item -LiteralPath (Join-Path $lab 'stub\atuin.exe')
	[Environment]::SetEnvironmentVariable('Path', "$lab\login-stub", 'User')

	# Missing repository: only rio fails, before any of its paths change.
	Move-Item -LiteralPath $rioRepo -Destination (Join-Path $lab 'aside\rio')
	Check 'repo_missing_exit' (Mod 'repo_missing' 'Invoke-WindowsApplications apply') 1
	Check 'repo_missing_reported' (Rows 'repo_missing' 'Unit=rio .*preflight failed: [^\n]*missing repository catppuccin/rio') 2
	Check 'repo_missing_only_rio' (Log 'repo_missing').Contains('did not complete for: rio') 'True'
	Check 'repo_missing_rio_dests' ((LinkOf $d.riotheme) + ',' + (LinkOf $d.rio)) 'absent,absent'
	Check 'repo_missing_others_applied' (Rows 'repo_missing' 'Action=created') 16
	$first = @([regex]::Matches((Log 'repo_missing'), 'Unit=(\w+)') | ForEach-Object { $_.Groups[1].Value })
	Check 'repo_missing_base_created_first' (@($first[0..6] | Where-Object { $_ -eq 'base' }).Count) 7
	Move-Item -LiteralPath (Join-Path $lab 'aside\rio') -Destination $rioRepo

	# Dirty repository: alacritty is applied and its source changed, so apply
	# would replace the copy; the dirty checkout blocks it and nothing changes.
	$alaBefore = Hash $d.alacritty
	$e162Bytes = [IO.File]::ReadAllBytes($e162)
	[IO.File]::AppendAllText($e162, "# lab source edit`n")
	[IO.File]::WriteAllText((Join-Path $alaRepo 'lab-untracked.txt'), "dirty`n", $lf)
	Check 'repo_dirty_exit' (Mod 'repo_dirty' 'Invoke-WindowsApplications apply') 1
	Check 'repo_dirty_reported' (Rows 'repo_dirty' 'Unit=alacritty .*State=stale .*preflight failed: [^\n]*dirty repository catppuccin/alacritty') 1
	Check 'repo_dirty_only_alacritty' (Log 'repo_dirty').Contains('did not complete for: alacritty') 'True'
	Check 'repo_dirty_dest_unchanged' ((Hash $d.alacritty) -eq $alaBefore) 'True'
	Check 'repo_dirty_rio_applied' ((LinkOf $d.riotheme) + ',' + (LinkOf $d.rio)) "SymbolicLink->$rioRepo\themes\catppuccin-mocha.toml,Junction->$(Live '~/.config/rio')"
	Remove-Item -LiteralPath (Join-Path $alaRepo 'lab-untracked.txt')
	[IO.File]::WriteAllBytes($e162, $e162Bytes)

	# Wrong origin: rio's junction is gone, so apply would recreate it; the
	# wrong origin blocks it and nothing changes.
	[IO.Directory]::Delete($d.rio, $false)
	$origin = (& $git -C $rioRepo config --get remote.origin.url)
	& $git -C $rioRepo remote set-url origin "$gh/example/rio"
	Check 'repo_origin_exit' (Mod 'repo_origin' 'Invoke-WindowsApplications apply') 1
	Check 'repo_origin_reported' (Rows 'repo_origin' 'Unit=rio .*preflight failed: [^\n]*wrong origin for repository catppuccin/rio') 2
	Check 'repo_origin_only_rio' (Log 'repo_origin').Contains('did not complete for: rio') 'True'
	Check 'repo_origin_rio_dests' ((LinkOf $d.riotheme) + ',' + (LinkOf $d.rio)) "SymbolicLink->$rioRepo\themes\catppuccin-mocha.toml,absent"
	& $git -C $rioRepo remote set-url origin $origin
	Say 'repo_origin_restored' ($origin -eq 'https://github.com/catppuccin/rio')

	# Every flagged unit applies, base first; validate exits 0.
	Check 'apply_exit' (Mod 'apply' 'Invoke-WindowsApplications apply') 0
	$units = @([regex]::Matches((Log 'apply'), 'Unit=(\w+)') | ForEach-Object { $_.Groups[1].Value })
	Check 'apply_base_first' (($units[0..6] -join ',') + '|' + @($units | Select-Object -Skip 7 | Where-Object { $_ -eq 'base' }).Count) 'base,base,base,base,base,base,base|0'
	Check 'apply_rio_created' (Rows 'apply' 'Unit=rio .*Action=created') 1
	Check 'validate_exit' (Mod 'validate' 'Invoke-WindowsApplications validate') 0
	Check 'validate_herdr_ok' (Rows 'validate' 'Unit=base \| Kind=Generated [^\n]*State=ok') 1
	# Validate fails while the Herdr output is missing, without a drift block.
	Move-Item -LiteralPath $herdr -Destination (Join-Path $lab 'aside\herdr.toml')
	Check 'herdr_missing_validate_exit' (Mod 'herdr_missing_validate' 'Invoke-WindowsApplications validate') 1
	Check 'herdr_missing_reported' (Rows 'herdr_missing_validate' 'Unit=base \| Kind=Generated [^\n]*State=absent') 1
	Check 'herdr_missing_no_sentinel' (Test-Path -LiteralPath (Join-Path $state 'blocked')) 'False'
	Move-Item -LiteralPath (Join-Path $lab 'aside\herdr.toml') -Destination $herdr
	Check 'status_exit' (Mod 'status' 'Invoke-WindowsApplications status') 0
	Check 'status_enabled_ok' (Rows 'status' 'Enabled=True [^\n]*State=ok') 18
	Check 'status_enabled_not_ok' (Rows 'status' 'Enabled=True [^\n]*State=(?!ok)') 0
	foreach ($n in '.bash_logout', '.bash_profile', '.bashrc') { Check "base_$n" (LinkOf (Live "~/$n")) "SymbolicLink->$(Live "~/.config/bash/$n")" }
	Check 'base_.hushlogin' (LinkOf (Live '~/.hushlogin')) "SymbolicLink->$(Live '~/.config/login/.hushlogin')"
	Check 'base_.profile' (LinkOf (Live '~/.profile')) "SymbolicLink->$(Live '~/.config/shell/.profile')"
	Check 'base_profile' (LinkOf $d.profile) "SymbolicLink->$(Live '~/.config/pwsh/Microsoft.PowerShell_profile.ps1')"
	Check 'base_mintty' (LinkOf $d.mintty) "Junction->$(Live '~/.config/mintty')"
	foreach ($n in 'bat', 'helix', 'ncspot', 'rtk') { Check "junction_$n" (LinkOf $d[$n]) "Junction->$(Live "~/.config/$n")" }
	Check 'junction_ncspot_reads_local' ((Hash (Join-Path $d.ncspot 'config.toml')) -eq (Hash (Live '~/.config/ncspot/config.toml'))) 'True'
	Check 'rio_dests' ((LinkOf $d.riotheme) + ',' + (LinkOf $d.rio)) "SymbolicLink->$rioRepo\themes\catppuccin-mocha.toml,Junction->$(Live '~/.config/rio')"
	Check 'rio_theme_through_junction' ((Hash (Join-Path $d.rio 'themes\catppuccin-mocha.toml')) -eq (Hash "$rioRepo\themes\catppuccin-mocha.toml")) 'True'
	foreach ($n in 'preview', 'stable') { Check "terminal_$n" (LinkOf $d[$n]) "SymbolicLink->$(Live '~/.config/windows/wind-term-settings.json')" }
	Check 'topgrade_copy' ((LinkOf $d.topgrade) + ':' + (Get-Item -LiteralPath $d.topgrade).IsReadOnly + ':' + ((Hash $d.topgrade) -eq (Hash (Live '~/.config/topgrade/topgrade.toml')))) 'plain:True:True'
	Check 'e163_copy' ((LinkOf $d.atuin) + ':' + (Get-Item -LiteralPath $d.atuin).IsReadOnly + ':' + ((Hash $d.atuin) -eq (Hash $e163))) 'plain:True:True'
	# The Sandbox image ships without the VBScript engine (a Windows optional
	# feature); run the launcher only where it exists.
	if ((Test-Path -LiteralPath "$env:WINDIR\System32\vbscript.dll") -and (Test-Path -LiteralPath 'Registry::HKEY_CLASSES_ROOT\VBScript')) {
		$env:PATH = "$lab\login-stub;$env:PATH"
		Check 'e163_runs_exit' (Run 'e163_runs' 'cscript.exe' @('//nologo', $d.atuin)) 0
		Check 'e163_runs_output' (Log 'e163_runs').Trim() ''
	}
	else { Say 'e163_runs' 'skipped: no VBScript engine in this guest' }
	$want = [IO.File]::ReadAllText($e162).Replace('{{ env.USERPROFILE }}', $env:USERPROFILE).Replace('{{ env.ProgramFiles }}', $env:ProgramFiles)
	$got = [IO.File]::ReadAllText($d.alacritty)
	Check 'e162_rendered' ((LinkOf $d.alacritty) + ':' + (Get-Item -LiteralPath $d.alacritty).IsReadOnly + ':' + ($got -eq $want) + ':' + $got.Contains('{{')) 'plain:True:True:False'
	Check 'e162_rendered_home' $got.Contains("working_directory = '$env:USERPROFILE'") 'True'
	Check 'e162_git_bash_exists' (Test-Path -LiteralPath "$env:ProgramFiles\Git\bin\bash.exe") 'True'

	# Unflagged units: no destination touched and no state recorded.
	Check 'unflagged_occupants_unchanged' ((LinkOf $d.espanso) + ',' + (LinkOf $d.harper) + ',' + (((Hash (Join-Path $d.espanso 'occupant.txt')) + (Hash $d.harper)) -eq $occ)) 'plain,plain,True'
	Check 'unflagged_state_files' (@(Get-ChildItem -LiteralPath $state -Filter '*.json' | Where-Object { $_.BaseName -in $unflagged }).Count) 0
	Check 'unflagged_status_disabled' (Rows 'status' 'Unit=(espanso|harper) \| Enabled=False') 2
	Check 'unflagged_apply_rows' (Rows 'apply' 'Unit=(espanso|harper) ') 0

	# Enabling them later applies them too.
	Remove-Item -LiteralPath $d.espanso -Recurse -Force
	Remove-Item -LiteralPath $d.harper -Force
	Flags @($optional | ForEach-Object { "$_ = true" })
	Check 'all_apply_exit' (Mod 'all_apply' 'Invoke-WindowsApplications apply') 0
	Check 'all_validate_exit' (Mod 'all_validate' 'Invoke-WindowsApplications validate') 0
	Mod 'all_status' 'Invoke-WindowsApplications status' | Out-Null
	Check 'all_status_ok' (Rows 'all_status' 'Enabled=True [^\n]*State=ok') 20
	Check 'espanso_junction' (LinkOf $d.espanso) "Junction->$(Live '~/.config/espanso')"
	Check 'harper_link' (LinkOf $d.harper) "SymbolicLink->$(Live '~/.config/harper-ls/dictionary.txt')"

	# No local input, module state, rendered output, or dependency link reaches history.
	Check 'final_save_exit' (Run 'final_save' $mise @('dot', 'save', '--description', 'Lab final')) 0
	# Stream paths only: the legacy ancestry still names the old ncspot and rio links.
	$leaked = @(& $git -C $H log --all --name-only --format= | Where-Object { $_ -match '^(home|config)(@\w+)?/' -and $_ -match 'windows-applications|config\.windows\.local|quarantine|ncspot|rio/themes|^home(@windows)?/AppData' })
	Check 'history_local_paths' $leaked.Count 0
	Say 'history_local_paths_list' ($leaked -join ';')
	Check 'history_marker_commits' (@(& $git -C $H log --all -S 'lab-marker-375-local' --format=%H).Count) 0
	Check 'history_rendered_home' (@(& $git -C $H log --all -S "$env:USERPROFILE" --format=%H).Count) 0

	# Round-4 GlazeWM/Zebar: the profile chain (E152 sources E149, then E148)
	# persists both as user variables. Two sessions run, the second inheriting
	# the user variables the first persisted; the first session's result is
	# recorded, the values after the second are checked.
	$envCmd = '. (Join-Path $HOME ''.config/pwsh/Initialize-Functions.ps1''); . (Join-Path $HOME ''.config/pwsh/Initialize-Environment.ps1'')'
	$refresh = 'foreach ($k in [Environment]::GetEnvironmentVariables(''User'').Keys) { if ($k -ne ''Path'') { Set-Item -LiteralPath (''env:'' + $k) -Value ([Environment]::GetEnvironmentVariable($k, ''User'')) } }; '
	Run 'pwsh_env_first' $pwsh @('-NoProfile', '-NonInteractive', '-Command', $envCmd) | Out-Null
	Say 'glazewm_set_after_first_session' ([bool][Environment]::GetEnvironmentVariable('GLAZEWM_CONFIG_PATH', 'User'))
	Run 'pwsh_env_next' $pwsh @('-NoProfile', '-NonInteractive', '-Command', ($refresh + $envCmd)) | Out-Null
	Check 'glazewm_config_path' ([Environment]::GetEnvironmentVariable('GLAZEWM_CONFIG_PATH', 'User')) (Live '~/.config/glazewm/config.yaml')
	Check 'zebar_config_dir' ([Environment]::GetEnvironmentVariable('ZEBAR_CONFIG_DIR', 'User')) (Live '~/.config/zebar')
	Say 'done' 'yes'
}
catch {
	Say 'error' $_.Exception.Message
	$script:fails += 'error'
}
finally {
	Say 'failed_checks' $(if ($script:fails.Count) { $script:fails -join ',' } else { 'none' })
	Say 'pass' $(if ($script:fails.Count) { 'no' } else { 'yes' })
	try { Stop-Transcript | Out-Null } catch { }
	shutdown.exe /s /t 5
}
