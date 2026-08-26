[CmdletBinding()]
param(
    [string]$GodotExecutable = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDirectory = Split-Path -Parent $PSCommandPath
$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptDirectory ".."))
$buildRoot = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot "build"))
$stageDirectory = [System.IO.Path]::GetFullPath((Join-Path $buildRoot "playtest"))
$executablePath = Join-Path $stageDirectory "Von-Neumann-Bottleneck.exe"
$playerReadmeSource = Join-Path $repositoryRoot "distribution\PLAYTEST-README.txt"
$playerReadmeDestination = Join-Path $stageDirectory "PLAYTEST-README.txt"
$zipPath = Join-Path $buildRoot "Von-Neumann-Bottleneck-Windows-Playtest.zip"

if (-not $stageDirectory.StartsWith($buildRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to prepare a staging directory outside the repository build folder."
}

if ([string]::IsNullOrWhiteSpace($GodotExecutable)) {
    foreach ($candidate in @("godot_console", "godot")) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($null -ne $command) {
            $GodotExecutable = $command.Source
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($GodotExecutable) -or -not (Test-Path -LiteralPath $GodotExecutable -PathType Leaf)) {
    throw "Godot 4.7.1 editor executable not found. Pass -GodotExecutable <path-to-godot.exe>."
}

$executableName = [System.IO.Path]::GetFileNameWithoutExtension($GodotExecutable)
if (-not $executableName.EndsWith("_console", [System.StringComparison]::OrdinalIgnoreCase)) {
    $consoleCandidate = Join-Path ([System.IO.Path]::GetDirectoryName($GodotExecutable)) ($executableName + "_console.exe")
    if (Test-Path -LiteralPath $consoleCandidate -PathType Leaf) {
        $GodotExecutable = $consoleCandidate
    }
}

$global:LASTEXITCODE = 0
$versionOutput = & $GodotExecutable --version
$versionExitCode = $LASTEXITCODE
$version = ($versionOutput | Select-Object -First 1).Trim()
if ($versionExitCode -ne 0 -or $version -notmatch '^4\.7\.1(?:\.|$)') {
    throw "This project requires Godot 4.7.1; found '$version'."
}

if (Test-Path -LiteralPath $stageDirectory) {
    Remove-Item -LiteralPath $stageDirectory -Recurse -Force
}
New-Item -ItemType Directory -Path $stageDirectory -Force | Out-Null

& $GodotExecutable --headless --path $repositoryRoot --export-release "Windows Playtest" $executablePath
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $executablePath -PathType Leaf)) {
    throw "Godot export failed. Install the matching 4.7.1 export templates with Editor > Manage Export Templates, then retry."
}

Copy-Item -LiteralPath $playerReadmeSource -Destination $playerReadmeDestination
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}
Compress-Archive -LiteralPath @($executablePath, $playerReadmeDestination) -DestinationPath $zipPath -CompressionLevel Optimal

$hash = Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath
Write-Host "Playtest package: $zipPath"
Write-Host "SHA256: $($hash.Hash)"
