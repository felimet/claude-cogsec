---
name: cogsec-hardening
description: Apply cogsec-derived hardening when configuring, auditing, or onboarding a Claude Code installation. Covers token optimization (Haiku/Sonnet/Opus tiering), memory persistence and rotation, evaluation harness, parallelization with worktrees, and the full agentic-security stack (CVEs, sandboxing, deny-list, sanitization, supply chain). Use when the user mentions hardening, security audit, cogsec, AgentShield, token cost optimization across model tiers, memory poisoning, untrusted repo workflows, or asks to set up a fresh Claude Code environment safely.
---

# cogsec-hardening

End-to-end reference compiled from the cogsec longform + shorthand guides. Five focus areas, each backed by a rule file under `rules/common/`.

## When to apply

- New Claude Code install on a workstation
- After a workflow that touched untrusted content (third-party PDFs, foreign repos, scraped web data)
- Before granting an agent broader permissions
- Quarterly hygiene checks

## Focus areas

### 1. Token optimization (`rules/common/token-optimization.md`)

- Tier hierarchy: Haiku for repetitive worker tasks (~3-5x cheaper), Sonnet as default for 90% of work, Opus only after failure or for architectural / security-critical scope.
- Replace `grep`/`rg` with `mgrep` where available (~50% token reduction).
- Run non-streaming background work via tmux outside Claude; feed back summaries.
- Files in hundreds of lines, not thousands.

### 2. Memory persistence (`rules/common/memory-persistence.md`)

- Three-scope separation: user-global (`~/.claude/memory/`), project (`.claude/`), session (TaskCreate).
- Never mix scopes. Rotate project memory after untrusted runs.
- Memory poisoning is real: payloads planted across sessions assemble later (Microsoft Feb 2026: 31 companies / 14 industries).
- Periodic scan: `rg -n 'ignore|override|system prompt|forget|disregard' ~/.claude/memory/`.

### 3. Evaluation (`rules/common/evaluation.md`)

- Modes: checkpoint-based (milestone verification), continuous (RL-style timer + test/lint).
- Worktree benchmarking: identical task in `eval-with-skill` vs `eval-without-skill` -> compare pass rate, token cost, diff size.
- Saturation check: 100% pass = test suite too easy.
- Observability: log per tool call to JSONL (this plugin installs the hook).

### 4. Parallelization (`rules/common/parallelization.md`)

- Orthogonal tasks only. Hard cap 3-4 active instances.
- Git worktrees mandatory for code overlap.
- Cascade method: left-to-right oldest-to-newest tabs.
- Scope definition required before fork.
- Feed `/llms.txt` directly when docs sites publish it.

### 5. Agentic security (`rules/common/agentic-security.md`)

- CVEs: CVE-2025-59536 (8.7) - `.claude/` executes pre-trust; CVE-2026-21852 - `ANTHROPIC_BASE_URL` overwrite. Keep Claude Code >= v2.0.65.
- Sandboxing: container with `network=none` for untrusted repos; agent identities separated from personal accounts.
- Deny list baseline: `templates/settings.deny-list.json`.
- Sanitization: Triple Threat Rule; scan zero-width / bidi unicode in external files.
- Supply chain: 36% of public skills carry prompt injection (Snyk ToxicSkills Feb 2026).
- Kill switches: process-group kill + heartbeat dead-man for unattended loops.

## Quick audit

Run `/cogsec-audit` (provided by this plugin).

## Minimum bar checklist

- [ ] Claude Code >= v2.0.65
- [ ] Deny list matches baseline
- [ ] `autoApproveTools: false`
- [ ] PostToolUse hook firing -> `~/.claude/logs/tool-calls.jsonl` growing
- [ ] Agent identities separated (Gmail / Slack / GitHub PAT)
- [ ] Memory scope separation; rotated after untrusted runs
- [ ] Skills / hooks / MCP scanned before use
- [ ] Container isolation available for untrusted work
- [ ] Heartbeat dead-man switch in autonomous loops
