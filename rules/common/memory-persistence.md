# Memory Persistence

## Proactive Memory Review

Memory review should happen every ~15 minutes during active sessions, not reactively.
Agent reviews recent interactions, proposes updates, user approves/rejects.
Over time, approval patterns teach the agent what to retain.

Use `/agentmemory:recall` at session start. Use `/agentmemory:remember` on validated insights.

## Scope Separation (CRITICAL for Security)

| Memory Type | Location | Use |
|-------------|----------|-----|
| User-global | `~/.claude/memory/` | Identity, preferences, cross-project patterns |
| Project | `.claude/` in repo | Project-specific context only |
| Session | TaskCreate/TaskUpdate | Current conversation progress only |

**Never mix project memory with user-global memory.**
After untrusted runs (foreign repos, email attachments, web scraping workflows), reset or rotate
project memory. Contamination can persist across sessions.

## What Belongs in Memory

Save only what is non-obvious and non-derivable from code:
- User role, preferences, collaboration style
- Feedback on past approaches (what worked / what to avoid and why)
- Project goals, constraints, decisions not in git history
- Cross-session lessons that would surprise a future reader

Do NOT save: file paths, code patterns, recent git changes, ephemeral task state.

## Memory Poisoning Risk

Memory is loaded at session start (Anthropic docs confirm this for Claude Code).
A payload planted in a previous session can assemble later.
- Microsoft memory poisoning report: 31 companies / 14 industries affected (Feb 2026)
- Fragments can be injected across multiple innocent-looking runs

Mitigations:
- Keep memory files narrow -- no secrets, no sensitive credentials
- Disable long-lived shared memory for high-risk workflows (mass web scraping, untrusted repos)
- Review `~/.claude/memory/` periodically after runs touching external content
- Scan for injected directives:

```bash
rg -n 'ignore|override|system prompt|forget|disregard' ~/.claude/memory/
```

## Rotation After Untrusted Work

After any workflow that processes:
- Third-party PDFs / DOCX / HTML attachments
- Foreign repository content
- Internet-scraped data

Clear or rotate the relevant memory files before the next privileged session.
