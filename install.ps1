# Manual installer for Windows / PowerShell users.
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $env:USERPROFILE ".claude" }

Write-Host "==> Installing cogsec-hardening into $ClaudeDir" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path "$ClaudeDir\rules\common" | Out-Null
New-Item -ItemType Directory -Force -Path "$ClaudeDir\hooks"        | Out-Null
New-Item -ItemType Directory -Force -Path "$ClaudeDir\logs"         | Out-Null

Copy-Item -Force "$ScriptDir\rules\common\*.md" "$ClaudeDir\rules\common\"
Copy-Item -Force "$ScriptDir\hooks\log-tool-call.js" "$ClaudeDir\hooks\"

Write-Host ""
Write-Host "==> Files installed." -ForegroundColor Green
Write-Host ""
Write-Host "Next: merge templates\settings.deny-list.json into ~/.claude/settings.json"
Write-Host "      under permissions.deny, and add top-level hooks.PostToolUse block."
Write-Host '      Hook command:  node "$HOME/.claude/hooks/log-tool-call.js"'
Write-Host '      Also set:  "autoApproveTools": false'
Write-Host ""
Write-Host "==> Verify:" -ForegroundColor Cyan
Write-Host "    claude --version    # must be >= v2.0.65"
Write-Host "    Get-Content $ClaudeDir\logs\tool-calls.jsonl -Tail 1"
Write-Host "==> Done." -ForegroundColor Green
