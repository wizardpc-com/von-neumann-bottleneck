param(
    [Parameter(Mandatory = $true)][ValidateSet('Install', 'Remove')][string]$Operation,
    [Parameter(Mandatory = $true)][string]$Rule,
    [Parameter(Mandatory = $true)][string]$Program,
    [Parameter(Mandatory = $true)][ValidateSet('IPv4', 'IPv6')][string]$Family,
    [Parameter(Mandatory = $true)][string]$AddressCsv
)

$ErrorActionPreference = 'Stop'
if ($env:RUNNER_ENVIRONMENT -ne 'github-hosted' -or $Rule -notmatch '^VNBReleaseQA-(game|test)-[0-9a-f]{32}$') {
    throw 'The Windows release firewall guard requires an isolated GitHub-hosted runner.'
}
$name = "${Rule}-${Family}"
if ($Operation -eq 'Remove') {
    Get-NetFirewallRule -Name $name -PolicyStore PersistentStore -ErrorAction SilentlyContinue |
        Remove-NetFirewallRule
    return
}

$binary = (Resolve-Path -LiteralPath $Program).Path
if (-not $binary.StartsWith($env:RUNNER_TEMP.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The Windows release firewall guard requires a disposable runner-temp executable.'
}
if (@(Get-Service -Name BFE, MpsSvc | Where-Object Status -ne 'Running').Count -ne 0) {
    throw 'Windows Filtering Platform or Defender Firewall is unavailable.'
}
$profiles = @(Get-NetFirewallProfile -PolicyStore ActiveStore)
if ($profiles.Count -ne 3 -or @($profiles | Where-Object Enabled -ne 'True').Count -ne 0) {
    throw 'Outbound isolation requires Defender Firewall enabled for every profile.'
}

# Install each address family separately. The caller verifies the returned
# effective prefixes as address sets, accepting Windows' mask normalization.
$blocked = $AddressCsv.Split(',')
New-NetFirewallRule -Name $name -DisplayName $name -PolicyStore PersistentStore -Profile Any `
    -Enabled True -Direction Outbound -Action Block -Protocol Any -Program $binary -RemoteAddress $blocked | Out-Null
$effective = Get-NetFirewallRule -Name $name -PolicyStore ActiveStore
$application = $effective | Get-NetFirewallApplicationFilter
$ports = $effective | Get-NetFirewallPortFilter
$addresses = @($effective | Get-NetFirewallAddressFilter | ForEach-Object RemoteAddress)
if ($effective.Enabled -ne 'True' -or $effective.Profile -ne 'Any' -or $effective.Direction -ne 'Outbound' -or
    $effective.Action -ne 'Block' -or $application.Program -ne $binary -or
    $ports.Protocol -ne 'Any' -or $addresses.Count -eq 0) {
    throw "Could not verify the effective $Family outbound block for the copied executable."
}
ConvertTo-Json -InputObject $addresses -Compress
