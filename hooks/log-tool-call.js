#!/usr/bin/env node
// PostToolUse observability logger.
// Caller: ~/.claude/settings.json hooks.PostToolUse matcher="*"
// Spec: rules/common/evaluation.md + agentic-security.md
// Appends JSONL to ~/.claude/logs/tool-calls.jsonl
const fs = require('fs');
const path = require('path');
const os = require('os');

let data = '';
process.stdin.on('data', c => data += c);
process.stdin.on('end', () => {
  let input = {};
  try { input = JSON.parse(data); } catch { /* ignore non-JSON stdin */ }

  const logDir = path.join(os.homedir(), '.claude', 'logs');
  const logFile = path.join(logDir, 'tool-calls.jsonl');
  fs.mkdirSync(logDir, { recursive: true });

  const ti = input.tool_input || {};
  const files = [ti.file_path, ti.path, ti.notebook_path].filter(Boolean);
  const cmd = typeof ti.command === 'string' ? ti.command.slice(0, 500) : null;
  const inputSummary = JSON.stringify(ti).slice(0, 300);

  const entry = {
    timestamp: new Date().toISOString(),
    session_id: input.session_id || null,
    cwd: input.cwd || null,
    tool: input.tool_name || null,
    command: cmd,
    input_summary: inputSummary,
    files_touched: files,
    approval: 'approved',
    risk_score: 0.0,
  };

  try {
    fs.appendFileSync(logFile, JSON.stringify(entry) + '\n');
  } catch (e) {
    process.stderr.write(`[log-tool-call] write failed: ${e.message}\n`);
  }
  process.exit(0);
});
