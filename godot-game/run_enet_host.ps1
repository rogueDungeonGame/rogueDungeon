param(
    [string]$GodotExe = "godot4",
    [string]$ProjectPath = $PSScriptRoot,
    [string]$HostAddress = "127.0.0.1",
    [ValidateRange(1, 65535)]
    [int]$Port = 19090
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

$args = @(
    "--path", $ProjectPath,
    "--",
    "--net=host",
    "--transport=enet_direct",
    "--auto-connect=true",
    "--host=$HostAddress",
    "--port=$Port"
)

$proc = Start-Process -FilePath $godot -ArgumentList $args -PassThru

Write-Host ""
Write-Host "ENet host started."
Write-Host ("  PID={0}" -f $proc.Id)
Write-Host ("  HostAddress={0}" -f $HostAddress)
Write-Host ("  Port={0}" -f $Port)
Write-Host ""
Write-Host ("Stop with: Stop-Process -Id {0}" -f $proc.Id)
