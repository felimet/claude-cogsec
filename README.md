# claude-cogsec

[English](README.md) · [繁體中文](README.zh-TW.md)

**Claude Code Cognitive Security** — a hardening pack for Claude Code, packaged as both a Claude Code plugin and a manual install script.

Implements the configuration prescribed by the cogsec / `affaan-m` guides:

- **Longform Guide to Everything Claude Code** — token optimization, memory persistence, evaluation, parallelization.
- **Shorthand Guide to Everything Agentic Security** — attack vectors, sandboxing, sanitization, CVEs, AgentShield.

## Sources

This plugin codifies the configuration prescribed by:

- [`affaan-m/ECC` — The Guides](https://github.com/affaan-m/ECC/tree/main#the-guides)
- [The Longform Guide to Everything Claude Code](https://x.com/affaanmustafa/status/2014040193557471352)
- [The Shorthand Guide to Everything Agentic Security](https://x.com/affaanmustafa/status/2033263813387223421)

> The name **cogsec** = *cognitive security*: defending the model's reasoning surface against prompt injection, memory poisoning, supply-chain payloads, and agent-identity abuse — distinct from classical infosec which defends the network/host surface.

## Contents

```
.claude-plugin/plugin.json     # plugin manifest
hooks/
  hooks.json                   # PostToolUse observability binding
  log-tool-call.js             # JSONL logger -> ~/.claude/logs/tool-calls.jsonl
commands/
  cogsec-audit.md              # /cogsec-audit slash command
skills/
  cogsec-hardening/SKILL.md    # consolidated reference
rules/common/
  token-optimization.md
  memory-persistence.md
  evaluation.md
  parallelization.md
  agentic-security.md
templates/
  settings.deny-list.json
  settings.full-example.json
install.sh / install.ps1
```

## Prerequisite — install ECC first

`claude-cogsec` builds on top of [`affaan-m/ECC`](https://github.com/affaan-m/ECC) (Everything Claude Code). Install ECC **before** `claude-cogsec` — it provides the rule pack layout, agent definitions, and the GateGuard hook that `claude-cogsec` extends.

```bash
# Add the ECC marketplace
/plugin marketplace add https://github.com/affaan-m/ECC

# Install the ECC plugin
/plugin install ecc@ecc
```

Then proceed to install `claude-cogsec` below.

## Installation

### Option A - plugin marketplace

```bash
claude /plugin marketplace add felimet/claude-cogsec
claude /plugin install cogsec-hardening@claude-cogsec
```

The plugin registers the PostToolUse hook, installs `/cogsec-audit`, exposes the `cogsec-hardening` skill. Rule files are copied via the install script (rules are not yet plugin-distributable in Claude Code).

### Option B - manual install

```bash
./install.sh          # Linux / macOS / WSL / Git Bash
```

```powershell
./install.ps1         # Native Windows PowerShell
```

Then merge `templates/settings.deny-list.json` into `~/.claude/settings.json` and add the `hooks.PostToolUse` block shown in `templates/settings.full-example.json`.

## What the plugin does

1. Logs every tool call to `~/.claude/logs/tool-calls.jsonl` (timestamp, session id, tool, command, files touched).
2. Adds `/cogsec-audit` - one-shot hygiene scan.
3. Installs `cogsec-hardening` skill - consolidated reference.
4. Provides deny list baseline - blocks reads/writes to SSH/AWS/GPG/`.env*`, blocks `curl|bash`, `wget|bash`, raw `ssh|scp|nc`.

## Manual settings.json edits

```jsonc
{
  "autoApproveTools": false,
  "hooks": { /* templates/settings.full-example.json */ },
  "permissions": {
    "deny": [ /* templates/settings.deny-list.json */ ]
  }
}
```

## Verification

```bash
ls -la ~/.claude/logs/tool-calls.jsonl
tail -1 ~/.claude/logs/tool-calls.jsonl
ls ~/.claude/rules/common/
claude --version              # >= v2.0.65
claude /cogsec-audit --deep   # after plugin enabled
```

## CVE patch status

| CVE | CVSS | Required version |
|-----|------|------------------|
| CVE-2025-59536 | 8.7 | Claude Code >= v1.0.111 |
| CVE-2026-21852 | n/a | Claude Code >= v2.0.65 |

## Layout rationale

- `rules/` mirrors `affaan-m/everything-claude-code` rule pack layout, mergeable with existing ECC installs.
- `hooks/hooks.json` uses `${CLAUDE_PLUGIN_ROOT}` so plugin path resolves regardless of install location.
- `skills/` uses Anthropic skill frontmatter so it loads via standard Skill tool.

## Fact-Forcing Gate

ECC ships a GateGuard hook (`pre:edit-write:gateguard-fact-force`) that intercepts the agent before any new file is created and forces it to answer four questions. `claude-cogsec` cooperates with this gate — the questions are reproduced here so you understand what they enforce.

### 1. Who will call this new file?

> **Name the file(s) and line(s) that will call this new file.**

The agent must name the files and line numbers that will `import`, `require`, read, or reference the new file. Ensures the new file is not an orphan and is actually consumed somewhere.

### 2. Confirm no existing file serves the same purpose

> **Confirm no existing file serves the same purpose (use Glob).**

The agent must run `Glob` to verify no equivalent file already exists. Prevents code duplication and confusion.

### 3. If the file reads/writes data, show field structure and date format

> **If this file reads/writes data files, show field names, structure, and date format.**

For config files, data files, API responses, and similar artifacts the agent must list field names, types, and date formats — using redacted or synthetic values, **never** raw production data.

### 4. Quote the user's instruction verbatim

> **Quote the user's current instruction verbatim.**

The agent must reproduce the user's request word-for-word, so it cannot drift from or hallucinate the actual ask.

### Purpose

A forcing function that makes the agent justify (a) file necessity, (b) integration points, (c) data format, and (d) alignment with the original requirement **before** touching disk. Stops agents from scattering unjustified files.

To bypass the gate during legitimate setup work:

```bash
ECC_GATEGUARD=off claude ...
# or add pre:edit-write:gateguard-fact-force to ECC_DISABLED_HOOKS
```

## License

MIT - see [LICENSE](LICENSE).

## References

- [Anthropic Claude Code plugin docs](https://docs.claude.com/en/docs/claude-code)
- [`affaan-m/ECC` — The Guides](https://github.com/affaan-m/ECC/tree/main#the-guides)
- [Longform Guide to Everything Claude Code](https://x.com/affaanmustafa/status/2014040193557471352)
- [Shorthand Guide to Everything Agentic Security](https://x.com/affaanmustafa/status/2033263813387223421)
- Snyk ToxicSkills report (Feb 2026)
- Check Point Research, Unit 42 prompt injection write-ups
- Microsoft memory poisoning report (Feb 2026)
