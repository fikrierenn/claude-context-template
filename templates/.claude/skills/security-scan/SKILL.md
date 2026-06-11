---
name: security-scan
description: Scan the Claude Code configuration (.claude/ directory) for security vulnerabilities, misconfigurations, and injection risks. Checks CLAUDE.md, settings.json, MCP server configs, hooks, and agent definitions.
---
<!-- Kaynak: ECC (github.com/affaan-m/ECC) — template'e uyarlandı -->

# Security Scan Skill

Audit the Claude Code configuration for security issues using local inspection (Read/Grep) — no external tools or services required.

## When to Activate

- Setting up a new Claude Code project
- After modifying `.claude/settings.json`, `CLAUDE.md`, or MCP configs
- Before committing configuration changes
- When onboarding to a new repository with existing Claude Code configs
- Periodic security hygiene checks

## What It Scans

| File | Checks |
|------|--------|
| `CLAUDE.md` | Hardcoded secrets, auto-run instructions, prompt injection patterns |
| `settings.json` / `settings.local.json` | Overly permissive allow lists, missing deny lists, dangerous bypass flags |
| `.mcp.json` / MCP configs | Risky MCP servers, hardcoded env secrets, npx supply chain risks |
| `hooks/` | Command injection via interpolation, data exfiltration, silent error suppression |
| `agents/*.md` | Unrestricted tool access, prompt injection surface, missing model specs |

## Scan Workflow

Run these phases with Read/Grep. Report findings with file:line and severity.

### Phase 1: Inventory

List the config surface: `CLAUDE.md`, `.claude/settings.json`, `.claude/settings.local.json`, `.mcp.json`, `.claude/hooks/`, `.claude/agents/`, `.claude/commands/`, `.claude/skills/`.

### Phase 2: Secrets Scan

Grep all config files for secret patterns:

```
sk-            # API key prefixes (OpenAI, Anthropic, Stripe...)
api[_-]?key
token
password
Bearer
AKIA           # AWS access key
connection string patterns (Server=, Password=, pwd=)
```

Any hardcoded value (not an env var reference like `${VAR}` / `$env:VAR`) is a finding.

### Phase 3: Permissions Review

In `settings.json` allow/deny lists:
- `Bash(*)` or other unrestricted wildcards in allow list
- Missing deny list entirely
- Dangerous bypass flags (`--dangerously-skip-permissions` in scripts/docs)
- Allow entries for destructive commands (`rm -rf`, `git push --force`, `git reset --hard`)

### Phase 4: Hooks Review

For each hook script:
- Command injection via interpolated variables (e.g. unquoted `${file}` passed to shell)
- Network calls to external hosts (curl/wget/Invoke-WebRequest) — potential exfiltration
- Silent error suppression (`2>/dev/null`, `|| true`, empty `catch {}`)
- Writes outside the project directory

### Phase 5: MCP Review

- Servers that execute arbitrary shell commands
- Hardcoded secrets in `env` blocks
- `npx -y` auto-install of unpinned packages (supply chain risk)
- Unnecessary servers wrapping CLI tools already available (`gh`, `git`, `npm`)

### Phase 6: CLAUDE.md and Agents

- Auto-run instructions ("always run X without asking") — prompt injection vector
- Instructions to ignore permissions or skip confirmation
- Agents with Bash/Write access they don't need (auditor/researcher agents should be read-only)

## Severity Classification

### Critical (fix immediately)
- Hardcoded API keys or tokens in config files
- `Bash(*)` in the allow list (unrestricted shell access)
- Command injection in hooks via unquoted interpolation
- Shell-running MCP servers

### High (fix before production)
- Auto-run instructions in CLAUDE.md (prompt injection vector)
- Missing deny lists in permissions
- Agents with unnecessary Bash access

### Medium (recommended)
- Silent error suppression in hooks (`2>/dev/null`, `|| true`)
- Missing PreToolUse security hooks
- `npx -y` auto-install in MCP server configs

### Info (awareness)
- Missing descriptions on MCP servers
- Prohibitive instructions correctly in place (good practice — note as passing)

## Output Format

```
CONFIG SECURITY SCAN
====================
Critical: N | High: N | Medium: N | Info: N

[CRITICAL] .claude/settings.json:12 — Bash(*) in allow list
  Fix: scope to specific commands, e.g. Bash(npm test:*), Bash(git status)

[HIGH] .claude/hooks/post-edit.sh:4 — unquoted ${file} interpolated into shell command
  Fix: quote the variable or pass via stdin
...
```

Fix only with user approval. Safe auto-fixes: replace hardcoded secrets with env var references, tighten wildcard permissions to scoped alternatives. Never silently rewrite hooks or agents — show the diff first.
