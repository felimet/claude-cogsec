# claude-cogsec

[English](README.md) · [繁體中文](README.zh-TW.md)

**Claude Code Cognitive Security** — Claude Code 認知安全強化套件，同時提供 Claude Code plugin 與手動安裝腳本。

落實 cogsec / `affaan-m` 指南所規範的配置：

- **Longform Guide to Everything Claude Code** — Token 優化、記憶體持久化、評估、並行化。
- **Shorthand Guide to Everything Agentic Security** — 攻擊向量、沙箱、清理、CVE、AgentShield。

## 來源（Sources）

本 plugin 將以下指南所規範的配置整理成可直接安裝的成品：

- [`affaan-m/ECC` — The Guides](https://github.com/affaan-m/ECC/tree/main#the-guides)
- [The Longform Guide to Everything Claude Code](https://x.com/affaanmustafa/status/2014040193557471352)
- [The Shorthand Guide to Everything Agentic Security](https://x.com/affaanmustafa/status/2033263813387223421)

> **cogsec** = *cognitive security*（認知安全）：防禦模型推理面被 prompt injection、memory poisoning、供應鏈 payload、agent 身分濫用入侵，與防禦網路／主機面的傳統 infosec 互補但獨立。

## 內容

```
.claude-plugin/plugin.json     # plugin manifest
hooks/
  hooks.json                   # PostToolUse 觀測 hook 綁定
  log-tool-call.js             # JSONL 記錄器 -> ~/.claude/logs/tool-calls.jsonl
commands/
  cogsec-audit.md              # /cogsec-audit slash command
skills/
  cogsec-hardening/SKILL.md    # 整合參考文件
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

## 前置作業 — 先安裝 ECC

`claude-cogsec` 建構於 [`affaan-m/ECC`](https://github.com/affaan-m/ECC)（Everything Claude Code）之上。**請先安裝 ECC**，它提供 rule pack 佈局、agent 定義、以及 `claude-cogsec` 所延伸的 GateGuard hook。

```bash
# 加入 ECC marketplace
/plugin marketplace add https://github.com/affaan-m/ECC

# 安裝 ECC plugin
/plugin install ecc@ecc
```

ECC 就緒後再進行下方的 `claude-cogsec` 安裝。

## 安裝

### 方式 A — plugin marketplace

```bash
claude /plugin marketplace add github:felimet/claude-cogsec
claude /plugin install cogsec-hardening@claude-cogsec
```

Plugin 會註冊 PostToolUse hook、安裝 `/cogsec-audit`、暴露 `cogsec-hardening` skill。`rules/` 因 Claude Code 目前尚未支援 plugin 分發規則檔，仍需透過安裝腳本複製到 `~/.claude/rules/common/`。

### 方式 B — 手動安裝

```bash
./install.sh          # Linux / macOS / WSL / Git Bash
```

```powershell
./install.ps1         # 原生 Windows PowerShell
```

接著把 `templates/settings.deny-list.json` 合併進 `~/.claude/settings.json`，並加入 `templates/settings.full-example.json` 中的 `hooks.PostToolUse` 區塊。

## Plugin 功能

1. **記錄每次工具呼叫**至 `~/.claude/logs/tool-calls.jsonl`（timestamp、session id、tool、command、files touched）。
2. **新增 `/cogsec-audit`** — 一次性安裝健檢。
3. **安裝 `cogsec-hardening` skill** — 整合參考文件。
4. **提供 deny list 基準** — 封鎖對 SSH/AWS/GPG/`.env*` 的讀寫，封鎖 `curl|bash`、`wget|bash`、裸 `ssh|scp|nc`。

## 手動 settings.json 編輯

```jsonc
{
  "autoApproveTools": false,
  "hooks": { /* 見 templates/settings.full-example.json */ },
  "permissions": {
    "deny": [ /* 見 templates/settings.deny-list.json */ ]
  }
}
```

## 驗證

```bash
ls -la ~/.claude/logs/tool-calls.jsonl
tail -1 ~/.claude/logs/tool-calls.jsonl
ls ~/.claude/rules/common/
claude --version              # 必須 >= v2.0.65
claude /cogsec-audit --deep   # plugin 啟用後執行
```

## CVE 修補狀態

| CVE | CVSS | 必要版本 |
|-----|------|----------|
| CVE-2025-59536 | 8.7 | Claude Code >= v1.0.111 |
| CVE-2026-21852 | n/a | Claude Code >= v2.0.65 |

## 佈局原理

- `rules/` 對齊 `affaan-m/everything-claude-code` 規則包佈局，可與既有 ECC 安裝共存。
- `hooks/hooks.json` 使用 `${CLAUDE_PLUGIN_ROOT}` 變數，plugin 路徑會自動解析。
- `skills/` 使用 Anthropic skill frontmatter，標準 Skill 工具會自動載入。

## Fact-Forcing Gate

ECC 內建 GateGuard hook（`pre:edit-write:gateguard-fact-force`），會在 agent 建立任何新檔案前攔截並強迫它回答四個問題。`claude-cogsec` 配合這個 gate 設計——以下逐一說明它強制的內容。

### 1. 誰會呼叫這個新檔案？

> **Name the file(s) and line(s) that will call this new file**

要求說明哪些檔案的哪幾行會 `import`、`require`、讀取或參考這個新檔案。確保新檔案不是孤兒，真的有人會用到它。

### 2. 確認沒有現有檔案做相同用途

> **Confirm no existing file serves the same purpose (use Glob)**

要求用 `Glob` 工具檢查專案裡是否已經有類似功能的檔案。避免重複建立功能相同的檔案，造成 code duplication 或混淆。

### 3. 如果檔案讀寫資料，說明欄位結構與格式

> **If this file reads/writes data files, show field names, structure, and date format**

針對設定檔、資料檔、API response 等需要明確資料結構的檔案，要求列出欄位名稱、資料型別、日期格式等。強制使用假資料或遮罩範例，**不能**直接貼生產資料。

### 4. 逐字引述使用者的原始指令

> **Quote the user's current instruction verbatim**

要求 agent 完整引用使用者當前的指令，確保 agent 理解對、沒有自己腦補或偏離原始需求。

### 目的

強迫 agent 在動手寫檔前先思考：(a) 檔案的必要性、(b) 整合點、(c) 資料格式、(d) 與原始需求的對齊度。算是一種「防止 agent 亂撒檔案」的 forcing function，讓它必須先講清楚理由再動作。

合法 setup 工作若被擋，可暫時繞過：

```bash
ECC_GATEGUARD=off claude ...
# 或加入 pre:edit-write:gateguard-fact-force 至 ECC_DISABLED_HOOKS
```

## 授權

MIT — 見 [LICENSE](LICENSE)。

## 參考

- [Anthropic Claude Code plugin docs](https://docs.claude.com/en/docs/claude-code)
- [`affaan-m/ECC` — The Guides](https://github.com/affaan-m/ECC/tree/main#the-guides)
- [Longform Guide to Everything Claude Code](https://x.com/affaanmustafa/status/2014040193557471352)
- [Shorthand Guide to Everything Agentic Security](https://x.com/affaanmustafa/status/2033263813387223421)
- Snyk ToxicSkills report (Feb 2026)
- Check Point Research、Unit 42 prompt injection 報告
- Microsoft memory poisoning report (Feb 2026)
