param(
    [string]$GodotExe = "godot4",
    [string]$ProjectPath = $PSScriptRoot,
    [ValidateRange(1, 10000000)]
    [int]$SteamAppId = 480,
    [ValidateSet("private", "friends_only", "public", "invisible")]
    [string]$LobbyVisibility = "friends_only",
    [ValidateRange(2, 8)]
    [int]$LobbyMaxMembers = 4,
    [ValidateRange(0, 65535)]
    [int]$VirtualPort = 0
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Resolve-GodotCommand {
    param([string]$InputPathOrCommand)

    if (Test-Path $InputPathOrCommand) {
        return (Resolve-Path $InputPathOrCommand).Path
    }

    $cmd = Get-Command $InputPathOrCommand -ErrorAction SilentlyContinue
    if ($null -ne $cmd) {
        return $cmd.Source
    }

    throw "Godot executable not found. Pass -GodotExe <absolute path to Godot.exe>"
}

if (-not (Test-Path (Join-Path $ProjectPath "project.godot"))) {
    throw "Invalid ProjectPath: project.godot not found -> $ProjectPath"
}

$godot = Resolve-GodotCommand -InputPathOrCommand $GodotExe

$env:SteamAppId = "$SteamAppId"
$env:SteamGameId = "$SteamAppId"

$args = @(
    "--path", $ProjectPath,
    "--",
    "--net=host",
    "--transport=steam_relay",
    "--auto-connect=true",
    "--steam-app-id=$SteamAppId",
    "--steam-virtual-port=$VirtualPort",
    "--lobby=create",
    "--lobby-enabled=true",
    "--lobby-visibility=$LobbyVisibility",
    "--lobby-members=$LobbyMaxMembers",
    "--host-migration=true"
)

$proc = Start-Process -FilePath $godot -ArgumentList $args -PassThru

Write-Host ""
Write-Host "Steam lobby host started."
Write-Host ("  PID={0}" -f $proc.Id)
Write-Host ("  SteamAppId={0}" -f $SteamAppId)
Write-Host ("  LobbyVisibility={0}" -f $LobbyVisibility)
Write-Host ("  LobbyMaxMembers={0}" -f $LobbyMaxMembers)
Write-Host ("  VirtualPort={0}" -f $VirtualPort)
Write-Host ""
Write-Host ("Stop with: Stop-Process -Id {0}" -f $proc.Id)
