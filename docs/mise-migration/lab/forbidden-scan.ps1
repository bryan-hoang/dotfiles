# Scans every blob at -Rev for the forbidden private-data classes (work
# identity, key identifiers, credentials, private endpoints) and prints one
# "path<TAB>class<TAB>lines" row per hit. It never prints matched values.
# -Text prints each line's classes joined by '+' (negative controls).
param([string]$Repo, [string]$Rev, [string[]]$Text)

# Public values the scan accepts: generic and vendor email domains, the
# public personal domain, and published vendor signing-key identifiers.
$script:AllowedEmailDomain = '^(example\.(com|org|net)|localhost|bryanhoang\.dev|(gist\.)?github\.com|users\.noreply\.github\.com|trollwut\.org)$'
$script:AllowedKeyId = @('64113EDF160FDEC2', '36F612DCF27F7D1A48A835E4DBFCF71C6D9F90A6', '3E9627155B7A6F29856321EE56D7FC25CF808407')
$script:Placeholder = '^(password|passwd|secret|token|changeme|example|xxx+|\*+|none|null|true|false)$'

# Returns the forbidden classes found on one line of text.
function Get-ForbiddenClass([string]$Line) {
	foreach ($m in [regex]::Matches($Line, '[A-Za-z0-9._%+-]+@([A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,})\b')) {
		$d = $m.Groups[1].Value.ToLower()
		if ($d -notmatch $script:AllowedEmailDomain -and $d -notmatch '\.(service|socket|target|timer)$') { 'work-identity'; break }
	}
	foreach ($m in [regex]::Matches($Line, '(?<![0-9A-Za-z])(?:0x)?([0-9A-F]{16}(?:[0-9A-F]{24})?)(?![0-9A-Za-z])')) {
		if ($script:AllowedKeyId -cnotcontains $m.Groups[1].Value) { 'key-identifier'; break }
	}
	if ($Line -match '(?i)(signing-?key|default-key|keyid|encrypt-to|recipient|local-user|--edit-key|--export(-secret)?-keys?|--sign-key|trusted-key|keygrip)\b[\s=:"'']+(0x)?[0-9A-Fa-f]{8,40}\b') { 'key-identifier' }
	$cred = $false
	foreach ($m in [regex]::Matches($Line, '(?i)\b[a-z0-9_.-]*(password|passwd|passphrase|secret|token|api[_-]?key|auth[_-]?key|_auth|client[_-]?secret|access[_-]?key)\b["'']?\s*[:=]\s*["'']?([^\s"''$<{}()\[\],;#]{4,})')) {
		if ($m.Groups[2].Value -notmatch $script:Placeholder) { $cred = $true }
	}
	if ($Line -match '-----BEGIN [A-Z ]*PRIVATE KEY-----' -or $Line -match '(?i)(pass(word|wd)?[_-]?(cmd|command|eval)|passwordeval)\b["'']?\s*[:=]\s*\S' -or $Line -match '(?i)[a-z][a-z0-9+.-]*://[^/\s:@\[\]]+:[^/\s@\[\]]+@') { $cred = $true }
	if ($cred) { 'credential' }
	if ($Line -match '(?<![\d.])(10\.\d{1,3}|192\.168|172\.(1[6-9]|2\d|3[01])|100\.(6[4-9]|[7-9]\d|1[01]\d|12[0-7]))\.\d{1,3}\.\d{1,3}(?![\d.])' -or
		$Line -match '(?i)(://|@)[a-z0-9.-]+\.(local|lan|internal|intranet|corp|home\.arpa|ts\.net)\b' -or
		$Line -match '(?i)\b[a-z0-9-]+\.(lan|intranet|home\.arpa|ts\.net)\b' -or
		$Line -cmatch '^\s*(HostName\s+\S|Host\s+[A-Za-z0-9][^=]*$)') { 'private-endpoint' }
}

if ($Text) { foreach ($line in $Text) { @(Get-ForbiddenClass $line | Select-Object -Unique) -join '+' } }
elseif ($Repo -and $Rev) {
	$env:MISE_AUTO_INSTALL = '0'
	foreach ($l in (& git -C $Repo ls-tree -r --full-tree $Rev)) {
		$meta, $path = $l -split "`t", 2
		$m, $type, $oid = $meta -split ' '
		if ($type -ne 'blob' -or $m -eq '120000') { continue }
		$counts = @{}
		foreach ($line in @(& git -C $Repo cat-file blob $oid)) {
			foreach ($c in @(Get-ForbiddenClass $line | Select-Object -Unique)) { $counts[$c]++ }
		}
		foreach ($c in ($counts.Keys | Sort-Object)) { "$path`t$c`t$($counts[$c])" }
	}
}
