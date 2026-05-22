---
description: Scan Claude Code installation for cogsec hygiene - prompt injection in skills/hooks/memory, version vs CVE fixes, deny-list completeness, observability hook health.
argument-hint: "[--quick | --deep]"
allowed-tools: Bash, Read, Grep, Glob
---

# Cogsec audit

Run a localized cogsec hygiene scan. Checklist source: `rules/common/agentic-security.md`.

## Scope

1. Claude Code version vs CVE-2026-21852 (>= v2.0.65) and CVE-2025-59536 (>= v1.0.111).
2. Permission deny-list in `~/.claude/settings.json` vs `templates/settings.deny-list.json`.
3. Supply chain scan of `~/.claude/plugins/` for outbound commands, `ANTHROPIC_BASE_URL`, `enableAllProjectMcpServers`, zero-width / bidi unicode.
4. Memory poisoning indicators in `~/.claude/memory/`.
5. PostToolUse hook present and `~/.claude/logs/tool-calls.jsonl` writable.
6. Warn if `autoApproveTools: true`.

## Steps

```bash
claude --version
jq '.permissions.deny // []' ~/.claude/settings.json
rg -n 'curl|wget|nc|ssh|scp|ANTHROPIC_BASE_URL|enableAllProjectMcpServers' ~/.claude/plugins/ 2>/dev/null
rg -nP '[\x{200B}-\x{200D}\x{202A}-\x{202E}\x{FEFF}]' ~/.claude/plugins/ 2>/dev/null
[ -d ~/.claude/memory ] && rg -in 'ignore|override|system prompt|forget|disregard' ~/.claude/memory/ 2>/dev/null
ls -la ~/.claude/logs/tool-calls.jsonl 2>/dev/null && tail -1 ~/.claude/logs/tool-calls.jsonl
jq '.autoApproveTools' ~/.claude/settings.json
```

## Output

Format: `[OK|WARN|CRIT] <check>: <finding>. <fix>.`

Sort by severity descending. End with: `audited: N / passed: M / warn: W / crit: C`.

If `$ARGUMENTS` contains `--deep`: diff installed deny-list vs `templates/settings.deny-list.json`; run `/ecc:security-scan` if ECC plugin installed.
