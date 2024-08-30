# Progress Bar Styling
$PSStyle.Progress.View = 'Classic'
$Host.privatedata.ProgressForegroundColor = "DarkGray"
$Host.privatedata.ProgressBackgroundColor = "Cyan"

# Module Scoped Variables
$script:LogDir = "$($PSScriptRoot)\Log"
$script:OutputLog = $false
$script:OutputCLI = $false
$script:OutputProgress = $false



