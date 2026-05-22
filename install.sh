#!/usr/bin/env bash
# Manual installer for users not using the Claude Code plugin marketplace.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"

echo "==> Installing cogsec-hardening into $CLAUDE_DIR"

mkdir -p "$CLAUDE_DIR/rules/common" "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/logs"

cp -v "$SCRIPT_DIR/rules/common/"*.md "$CLAUDE_DIR/rules/common/"
cp -v "$SCRIPT_DIR/hooks/log-tool-call.js" "$CLAUDE_DIR/hooks/"

cat <<'EOF'

==> Files installed.

Next: merge templates/settings.deny-list.json into ~/.claude/settings.json under
"permissions.deny", and add this top-level "hooks" block:

  "hooks": {
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": "node \"$HOME/.claude/hooks/log-tool-call.js\"" }
        ]
      }
    ]
  }

Also set:  "autoApproveTools": false

==> Verify:
    claude --version       # must be >= v2.0.65
    tail -1 ~/.claude/logs/tool-calls.jsonl

==> Done.
EOF
