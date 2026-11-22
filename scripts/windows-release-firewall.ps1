param(
    [Parameter(Mandatory = $true)][ValidateSet('Install', 'Remove')][string]$Operation,
    [Parameter(Mandatory = $true)][string]$Rule,
    [Parameter(Mandatory = $true)][string]$Program
)

$ErrorActionPreference = 'Stop'
if ($env:RUNNER_ENVIRONMENT -ne 'github-hosted' -or $Rule -notmatch '^VNBReleaseQA-[0-9a-f]{32}$') {
    throw 'The Windows release firewall guard requires an isolated GitHub-hosted runner.'
}
if ($Operation -eq 'Remove') {
    Get-NetFirewallRule -Name $Rule -PolicyStore PersistentStore -ErrorAction SilentlyContinue |
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

# Block all IPv6 and all IPv4 except 127/8. The app config further restricts HTTP to 127.0.0.1.
$blocked = @('0.0.0.0-126.255.255.255', '128.0.0.0-255.255.255.255', '::/0')
New-NetFirewallRule -Name $Rule -DisplayName $Rule -PolicyStore PersistentStore -Profile Any `
    -Enabled True -Direction Outbound -Action Block -Program $binary -RemoteAddress $blocked | Out-Null
$effective = Get-NetFirewallRule -Name $Rule -PolicyStore ActiveStore
$application = $effective | Get-NetFirewallApplicationFilter
$addresses = @($effective | Get-NetFirewallAddressFilter | ForEach-Object RemoteAddress)
if ($effective.Enabled -ne 'True' -or $effective.Profile -ne 'Any' -or $effective.Direction -ne 'Outbound' -or
    $effective.Action -ne 'Block' -or $application.Program -ne $binary -or
    $null -ne (Compare-Object -ReferenceObject $blocked -DifferenceObject $addresses)) {
    throw 'Could not verify the effective non-loopback block for the copied executable.'
}
