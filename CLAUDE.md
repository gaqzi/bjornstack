# Agent Instructions

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:b9766037 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->

## Git Conventions

- Tag commits with the bead ID at the end of the subject line when the commit delivers work for that bead: `Short description (bs-xxx)`
- When a commit addresses multiple beads, list them: `Short description (bs-xxx, bs-yyy)`
- Omit the tag when a commit is not tied to any bead (e.g., repo-wide conventions, config changes)

## Sandbox Workarounds

- Always run `bd` commands with `dangerouslyDisableSandbox: true` — Dolt needs raw TCP to localhost:3308 which the sandbox blocks (`excludedCommands` has upstream bugs)

## BEADS PROVENANCE

Load the /beads-provenance skill before any `bd` command, when a bead ID appears in conversation, or when implementation work produces findings worth logging. The skill has checklists for creating, claiming, updating, and closing beads — follow them. The goal: every bead should establish provenance — what was tried, what failed, why we ended up here — so future readers can evaluate the reasoning, not just see the conclusion.

## COMMIT STYLE

Load the /commit-style skill before writing any commit message. Tim Pope style: imperative mood, capitalized, 50-char subject hard limit, no trailing period, no conventional commit prefixes (feat:, fix:, etc.). Wrap body at 72 chars. Always use HEREDOC formatting.
