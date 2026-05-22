# Token Optimization

## Model Selection (Primary Strategy)

Delegate to cheapest model sufficient for the task. Never upgrade by default.

| Model | Use When |
|-------|----------|
| **Haiku** | Repetitive tasks, clear instructions, worker in multi-agent setup, file search, grep, simple code gen |
| **Sonnet** | 90% of coding tasks, orchestration, multi-file edits, default choice |
| **Opus** | First attempt failed, task spans 5+ files, architectural decisions, security-critical code |

Haiku vs Opus = 5x cost difference. Haiku vs Sonnet ~3x savings.
Sonnet vs Opus = 1.67x. The Haiku-Opus combo maximizes savings.

In agent definitions, specify model explicitly:

```yaml
---
name: quick-search
description: Fast file search
tools: Glob, Grep
model: haiku
---
```

## Tool-Specific Optimization

Replace `grep`/`rg` with `mgrep` where available — ~50% token reduction on average.
Source: github.com/mixedbread-ai/mgrep

## Background Processes

Run non-streaming background work outside Claude (via tmux). Feed only the relevant output
excerpt or summary into Claude, not the full raw stream. Input tokens dominate cost.

## Modular Codebase

Files in the hundreds of lines (not thousands) reduce re-reads, tool call chains, and
mid-file context loss. Every extra read costs tokens twice: input + model's output about it.

Target structure:
```
src/modules/<domain>/
├── api/             # Public interface
├── domain/          # Business logic (pure)
├── infrastructure/  # DB, external clients
├── use-cases/       # Orchestration
└── tests/
```

## System Prompt Slimming (Advanced)

Claude Code's system prompt ~18k tokens (~9% of 200k context).
Can be reduced to ~10k with YK's system-prompt-patches (saves ~7,300 tokens, 41% of static overhead).
Only worth it for high-volume / cost-constrained setups.

## Dead Code = Wasted Tokens

Use `/ecc:refactor-clean` and `/ecc:prune` periodically to eliminate dead code.
Leaner codebase -> cheaper per-task cost -> fewer multi-pass retries.

## Benchmarking Model Tiers

To find the right model per task empirically:
1. Create a repo with well-defined tasks and a clear plan
2. For each model tier, run all subagents as that model in a dedicated git worktree
3. Log task completion in plan/tasks
4. Compare: `git diff` across worktrees, uniform unit/integration/E2E tests
5. Numerical benchmark = cases passed / cases failed
6. If all pass: add harder edge cases or increase test complexity
