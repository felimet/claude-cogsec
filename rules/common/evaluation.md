# Evaluation & Benchmarking

## Two Eval Modes

CHECKPOINT-BASED: Verify task completion at defined milestones.
- Task -> Checkpoint -> pass? continue : fix -> retry
- Use for feature development with well-defined completion criteria

CONTINUOUS (RL-style): Timer or change event triggers test + lint run.
- pass -> continue | fail -> stop & fix
- Use for long-running autonomous loops and skill regression monitoring

## Skill Benchmarking (Worktree Method)

Compare skill-enabled vs baseline on the same task:

```bash
git worktree add ../eval-with-skill    feature-with
git worktree add ../eval-without-skill feature-without
```

Steps:
1. Run identical task in each worktree
2. Log tool calls and token usage via PostToolUse hook
3. Run uniform test suite across both worktrees
4. Compute: pass rate, token cost, diff size

Fork the conversation -> new worktree without skill -> run -> git diff -> compare logs.

## Observability for Evals

Minimum log fields per tool call:
```json
{
  "timestamp": "ISO8601",
  "session_id": "string",
  "tool": "string",
  "input_summary": "string",
  "files_touched": ["string"],
  "approval": "approved|blocked",
  "token_estimate": 0
}
```

Two approaches:
- tmux tracing: hook to thinking stream + output when skill triggers
- PostToolUse hook: log tool name, input summary, output hash, files touched

## Saturation Check

100% pass rate = test suite too easy. Add edge cases or increase complexity
until at least one model tier fails. Saturation renders the benchmark useless.

## Integration with Agents

Use `ecc:eval-harness` or `ecc:gan-build` skills for structured eval harness construction.
Tie results to `ecc:benchmark` for cross-session tracking.
