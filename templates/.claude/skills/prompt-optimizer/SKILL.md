---
name: prompt-optimizer
description: >-
  Analyze raw prompts, identify intent and gaps, match available project
  components (skills/commands/agents), and output a ready-to-paste optimized
  prompt. Advisory role only — never executes the task itself.
  TRIGGER when: user says "optimize prompt", "improve my prompt",
  "how to write a prompt for", "help me prompt", "rewrite this prompt",
  or explicitly asks to enhance prompt quality.
  DO NOT TRIGGER when: user wants the task executed directly, or says
  "just do it". DO NOT TRIGGER for "optimize this code" or "optimize
  performance" — those are refactoring/performance tasks, not prompt
  optimization.
---
<!-- Kaynak: ECC (github.com/affaan-m/ECC) — template'e uyarlandı -->

# Prompt Optimizer

Analyze a draft prompt, critique it, match it to the components actually
installed in this project (skills, commands, agents, rules), and output a
complete optimized prompt the user can paste and run.

## When to Use

- User says "optimize this prompt", "improve my prompt", "rewrite this prompt"
- User says "help me write a better prompt for..."
- User says "what's the best way to ask Claude Code to..."
- User pastes a draft prompt and asks for feedback or enhancement
- User says "I don't know how to prompt for this"

### Do Not Use When

- User wants the task done directly (just execute it)
- User says "optimize this code" or "optimize performance" — these are refactoring tasks, not prompt optimization
- User says "just do it"

## How It Works

**Advisory only — do not execute the user's task.**

Do NOT write code, create files, run commands, or take any implementation
action. Your ONLY output is an analysis plus an optimized prompt.

If the user says "just do it" or "don't optimize, just execute", do not switch
into implementation mode inside this skill. Tell the user this skill only
produces optimized prompts, and instruct them to make a normal task request if
they want execution instead.

Run this 6-phase pipeline sequentially. Present results using the Output Format below.

### Phase 0: Project Detection

Before analyzing the prompt, detect the current project context:

1. Check if a `CLAUDE.md` exists in the working directory — read it for project conventions
2. Detect tech stack from project files:
   - `package.json` → Node.js / TypeScript / React / Next.js
   - `go.mod` → Go
   - `pyproject.toml` / `requirements.txt` → Python
   - `Cargo.toml` → Rust
   - `build.gradle` / `pom.xml` → Java / Kotlin
   - `Package.swift` → Swift
   - `Gemfile` → Ruby
   - `composer.json` → PHP
   - `*.csproj` / `*.sln` → .NET
   - `Makefile` / `CMakeLists.txt` → C / C++
3. Note detected tech stack for use in Phase 3 and Phase 4

If no project files are found (e.g., the prompt is abstract or for a new project),
skip detection and flag "tech stack unknown" in Phase 4.

### Phase 1: Intent Detection

Classify the user's task into one or more categories:

| Category | Signal Words | Example |
|----------|-------------|---------|
| New Feature | build, create, add, implement | "Build a login page" |
| Bug Fix | fix, broken, not working, error | "Fix the auth flow" |
| Refactor | refactor, clean up, restructure | "Refactor the API layer" |
| Research | how to, what is, explore, investigate | "How to add SSO" |
| Testing | test, coverage, verify | "Add tests for the cart" |
| Review | review, audit, check | "Review my PR" |
| Documentation | document, update docs | "Update the API docs" |
| Infrastructure | deploy, CI, docker, database | "Set up CI/CD pipeline" |
| Design | design, architecture, plan | "Design the data model" |

### Phase 2: Scope Assessment

If Phase 0 detected a project, use codebase size as a signal. Otherwise, estimate
from the prompt description alone and mark the estimate as uncertain.

| Scope | Heuristic | Orchestration |
|-------|-----------|---------------|
| TRIVIAL | Single file, < 50 lines | Direct execution |
| LOW | Single component or module | Single skill or direct execution |
| MEDIUM | Multiple components, same domain | Plan + implement + verify |
| HIGH | Cross-domain, 5+ files | Written plan first, then phased execution |
| EPIC | Multi-session, multi-PR, architectural shift | Multi-session plan with handoff notes between sessions |

### Phase 3: Project Component Matching

**Inventory first, recommend second.** Scan what is actually installed:

1. `.claude/skills/*/SKILL.md` — read names and descriptions
2. `.claude/agents/*.md` — available subagents
3. `.claude/commands/*.md` — available slash commands
4. `.claude/rules/` — active rule files relevant to the task

Map intent + scope + tech stack to the components found. Typical mappings
(use only if the component exists in this project):

| Intent | Typical Components |
|--------|--------------------|
| New Feature | tdd-workflow, verification-loop, plan-first rule, code review agent |
| Bug Fix | tdd-workflow (failing test first), verification-loop |
| Refactor | verification-loop, before-major-change rule, code review agent |
| Research | search-first, codebase-onboarding |
| Testing | tdd-workflow, e2e-testing, python-testing |
| Review | security-scan, security/code review agents |
| Infrastructure | docker-patterns, deployment-patterns, database-migrations |
| Design | architecture-decision-records, plan-first rule |
| Stack-specific | dotnet-patterns, python-patterns, frontend-patterns, backend-patterns, api-design, coding-standards |

**Never recommend a component you have not verified exists in this project.**

### Phase 4: Missing Context Detection

Scan the prompt for missing critical information. Check each item and mark
whether Phase 0 auto-detected it or the user must supply it:

- [ ] **Tech stack** — Detected in Phase 0, or must user specify?
- [ ] **Target scope** — Files, directories, or modules mentioned?
- [ ] **Acceptance criteria** — How to know the task is done?
- [ ] **Error handling** — Edge cases and failure modes addressed?
- [ ] **Security requirements** — Auth, input validation, secrets?
- [ ] **Testing expectations** — Unit, integration, E2E?
- [ ] **Performance constraints** — Load, latency, resource limits?
- [ ] **UI/UX requirements** — Design specs, responsive, a11y? (if frontend)
- [ ] **Database changes** — Schema, migrations, indexes? (if data layer)
- [ ] **Existing patterns** — Reference files or conventions to follow?
- [ ] **Scope boundaries** — What NOT to do?

**If 3+ critical items are missing**, ask the user up to 3 clarification
questions before generating the optimized prompt. Then incorporate the
answers into the optimized prompt.

### Phase 5: Workflow & Model Recommendation

Determine where this prompt sits in the development lifecycle:

```
Research → Plan → Implement (TDD) → Review → Verify → Commit
```

For MEDIUM+ tasks, always start with a written plan.

**Model recommendation** (include in output):

| Scope | Recommended Model | Rationale |
|-------|------------------|-----------|
| TRIVIAL-LOW | Haiku / Sonnet | Fast, cost-efficient for simple tasks |
| MEDIUM | Sonnet | Balanced coding model for standard work |
| HIGH | Sonnet (implementation) + Opus (planning) | Deep reasoning for architecture, speed for code |
| EPIC | Opus (planning) + Sonnet (execution) | Deep reasoning for multi-session planning |

**Multi-prompt splitting** (for HIGH/EPIC scope):

For tasks that exceed a single session, split into sequential prompts:
- Prompt 1: Research + Plan (use the search-first skill, then write the plan)
- Prompt 2-N: Implement one phase per prompt (each ends with a verification pass)
- Final Prompt: Integration test + code review across all phases
- Use the session-handoff skill between sessions to preserve context

---

## Output Format

Present your analysis in this exact structure. Respond in the same language
as the user's input.

### Section 1: Prompt Diagnosis

**Strengths:** List what the original prompt does well.

**Issues:**

| Issue | Impact | Suggested Fix |
|-------|--------|---------------|
| (problem) | (consequence) | (how to fix) |

**Needs Clarification:** Numbered list of questions the user should answer.
If Phase 0 auto-detected the answer, state it instead of asking.

### Section 2: Recommended Components

| Type | Component | Purpose |
|------|-----------|---------|
| Skill | tdd-workflow | TDD methodology guidance |
| Agent | (verified project agent) | Post-implementation review |
| Rule | plan-first | Plan before coding |
| Model | Sonnet | Recommended for this scope |

### Section 3: Optimized Prompt — Full Version

Present the complete optimized prompt inside a single fenced code block.
The prompt must be self-contained and ready to copy-paste. Include:
- Clear task description with context
- Tech stack (detected or specified)
- Skill/command invocations at the right workflow stages
- Acceptance criteria
- Verification steps
- Scope boundaries (what NOT to do)

### Section 4: Optimized Prompt — Quick Version

A compact version for experienced users. Vary by intent type:

| Intent | Quick Pattern |
|--------|--------------|
| New Feature | `Plan [feature] first. Implement with TDD. Review, then verify.` |
| Bug Fix | `Write a failing test for [bug]. Fix to green. Verify.` |
| Refactor | `Refactor [scope]; existing tests must stay green. Review + verify.` |
| Research | `Use the search-first skill for [topic]. Plan based on findings.` |
| Testing | `Add tests for [module] (tdd-workflow). E2E for critical flows.` |
| Review | `Review the diff for bugs + run security-scan on config changes.` |
| EPIC | `Write a phased multi-session plan for "[objective]" with verify gates.` |

### Section 5: Enhancement Rationale

| Enhancement | Reason |
|-------------|--------|
| (what was added) | (why it matters) |

### Footer

> Not what you need? Tell me what to adjust, or make a normal task request
> if you want execution instead of prompt optimization.

---

## Example

**User input:**
```
Add a REST API endpoint for user profile updates with validation
```

**Phase 0 detects:** `go.mod` with Go 1.22, Chi router

**Optimized Prompt (Full):**
```
Add a REST API endpoint for user profile updates (PATCH /api/users/:id).

Tech stack: Go 1.22 + Chi router (detected from project)

Requirements:
- PATCH /api/users/:id — partial update of user profile
- Input validation for fields: name, email, avatar_url, bio
- Auth: require valid token, users can only update own profile
- Return 200 with updated user on success
- Return 400 with validation errors on invalid input
- Return 401/403 for auth failures
- Follow existing API patterns in the codebase (see api-design skill)

Workflow:
1. Plan the endpoint structure, middleware chain, and validation logic
2. TDD — write table-driven tests for success, validation failure, auth failure, not-found
3. Implement following existing handler patterns
4. Code review pass
5. Verify — run full test suite, confirm no regressions

Do not:
- Modify existing endpoints
- Change the database schema (use existing user table)
- Add new dependencies without checking existing ones first (use search-first skill)
```

---

## Related Components

| Component | When to Reference |
|-----------|------------------|
| `search-first` | Research phase in optimized prompts |
| `strategic-compact` | Long session context management |
| `session-handoff` | Preserving context between multi-session prompts |
| `context-budget` | When the optimized workflow would load many components |
