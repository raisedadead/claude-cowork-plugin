# dotplugins

Personal [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin marketplace.

## Setup

```bash
claude plugin marketplace add raisedadead/dotplugins
claude plugin install dp-cto@dotplugins
```

## dp-cto — CTO Orchestration

Orchestrate development with [Agent Teams](https://docs.anthropic.com/en/docs/claude-code/agent-teams), iterative loops, and research validation. Complementary to [superpowers](https://github.com/obra/superpowers) — superpowers handles individual contributor skills (TDD, debugging, code review); dp-cto handles orchestration and execution.

| Skill                  | What it does                                                         |
| ---------------------- | -------------------------------------------------------------------- |
| `/dp-cto:start`        | Brainstorm approaches, write implementation plan to `.claude/plans/` |
| `/dp-cto:execute`      | Execute a plan with Agent Teams and optional worktree isolation      |
| `/dp-cto:ralph`        | Teammate-based iterative loop with fresh context per iteration       |
| `/dp-cto:ralph-cancel` | Cancel an active ralph loop                                          |
| `/dp-cto:verify`       | Manual deep-validation of research findings                          |

**Workflow:**

```
/dp-cto:start    → brainstorm, explore design, write plan
/dp-cto:execute  → dispatch agents to execute plan in parallel
```

**Hooks:**

- **SessionStart** — injects enforcement context into every session
- **PreToolUse** — intercepts superpowers orchestration skills (e.g. `executing-plans`, `dispatching-parallel-agents`) and redirects to dp-cto equivalents; passes through quality skills (TDD, code review, debugging)
- **PostToolUse** — injects verification checklists after `WebSearch`, `WebFetch`, and MCP tool calls
- **Stage enforcement** — tracks workflow stage (`idle → start → planned → execute → executing → complete`) and blocks out-of-order transitions

## Structure

```
dotplugins/
├── .claude-plugin/marketplace.json
└── plugins/
    └── dp-cto/
        ├── .claude-plugin/plugin.json
        ├── hooks/
        │   ├── hooks.json
        │   ├── session-start.sh
        │   ├── session-cleanup.sh
        │   ├── intercept-orchestration.sh
        │   ├── stage-transition.sh
        │   ├── lib-stage.sh
        │   └── research-validator.sh
        └── skills/
            ├── start/SKILL.md
            ├── execute/SKILL.md
            ├── ralph/SKILL.md
            ├── ralph-cancel/SKILL.md
            └── verify/SKILL.md
```
