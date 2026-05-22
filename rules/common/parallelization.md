# Parallelization

## Core Principle

Goal: maximum output with minimum viable instance count.
Add a terminal only when there is genuine necessity, not to feel productive.
Most tasks complete efficiently with 2-3 Claude instances.

## When to Parallelize

Parallelize when tasks are **orthogonal** -- minimal shared file/state overlap.
Do NOT parallelize tasks that touch the same files; merge conflicts negate all gains.

Good candidates for parallel forks:
- Main chat: active code changes
- Fork 1: codebase questions / state inspection (read-only)
- Fork 2: external research (documentation, GitHub search)

Bad candidates:
- Two instances editing the same module
- Two instances both running migrations
- Arbitrary instance counts without scoped plans

## Git Worktrees (Required for Code Overlap)

Whenever multiple instances touch overlapping code, use worktrees:

```bash
git worktree add ../project-feature-a feature-a
git worktree add ../project-feature-b feature-b
git worktree add ../project-refactor   refactor-branch
```

Each worktree gets its own Claude instance. No git conflicts. Easy output comparison.
Name each chat with `/rename <name>` to avoid confusion when resuming sessions.

## The Cascade Method

Organize instances left-to-right, oldest-to-newest:

```
[Tab 1: Main] [Tab 2: Research] [Tab 3: Feature-B] -> oldest to newest
```

- Sweep left-to-right when checking progress
- Hard cap: 3-4 active tasks. Mental overhead grows faster than productivity beyond this.

## Scope Definition (Mandatory Before Fork)

Before forking any conversation, define:
1. Exact files/modules in scope for this instance
2. Files/modules explicitly out of scope (read-only or no-touch)
3. Expected output format (diff, summary, test results)
4. Merge strategy: who integrates the results

No scope definition = no fork.

## Two-Instance Kickoff Pattern

For fresh projects:
- **Instance 1 (Scaffolding)**: project structure, CLAUDE.md, rules, agents, skeleton
- **Instance 2 (Research)**: PRD, architecture diagrams, documentation references

Left terminal = coding. Right terminal = questions/research.

## llms.txt

Many documentation sites expose `/llms.txt` at their docs root.
LLM-optimized flat version of the docs -- feed directly, skip scraping overhead.
Example: `https://www.helius.dev/docs/llms.txt`
