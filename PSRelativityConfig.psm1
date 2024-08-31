# Progress Bar Styling
$PSStyle.Progress.View = 'Classic'
$Host.privatedata.ProgressForegroundColor = "DarkGray"
$Host.privatedata.ProgressBackgroundColor = "Cyan"

# Module Scoped Variables
$script:LogDir = "$($PSScriptRoot)\Log"
$script:OutputLog = $false
$script:OutputCLI = $false
$script:OutputProgress = $false

$isAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if(-not $isAdmin){ Write-Host "WARNING - Run as Administrator is required for scripts targetting localhost." -ForegroundColor Yellow }

