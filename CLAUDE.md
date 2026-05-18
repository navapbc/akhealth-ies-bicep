# Claude Code Project Configuration — akhealth-ies-bicep

Azure Bicep IaC repo deploying at **subscription scope**. There is no application code, no test runner, and no in-repo CI — CI runs in Azure DevOps Pipelines, defined outside this repo. See `.claude/project-understanding.md` for the full DSO onboarding record.

## Quick Reference — Bicep Commands

| Action | Command |
|---|---|
| Compile / lint | `bicep build main.bicep` |
| Validate (dry-run) | `az deployment sub validate --location <region> --template-file main.bicep --parameters params/<env>.bicepparam` |
| Preview changes | `az deployment sub what-if   --location <region> --template-file main.bicep --parameters params/<env>.bicepparam` |
| Deploy | `az deployment sub create   --location <region> --template-file main.bicep --parameters params/<env>.bicepparam` |

Local runs use interactive `az login`. The CI pipeline (Azure DevOps, outside this repo) uses a managed identity. Secrets come from pipeline variable groups or Key Vault references in Bicep.

## Repo Layout

- `main.bicep` — single subscription-scope entry point
- `modules/` — per-resource Bicep modules
- `params/` — one `.bicepparam` file per environment
- `artifacts/` — local-only build/deploy artifacts (not committed)
- `documentation/` — project-specific docs (see `readme.md` for the source-of-truth overview)

## Quick Reference — DSO Tickets

All ticket operations go through the shim at `.claude/scripts/dso`. Direct edits to `.tickets-tracker/` are blocked by a runtime guard — always use these commands:

| Action | Command |
|---|---|
| Create a task | `.claude/scripts/dso ticket create task "Short title"` |
| Create a bug | `.claude/scripts/dso ticket create bug "Short title"` |
| Show ticket | `.claude/scripts/dso ticket show <ID>` |
| List tickets | `.claude/scripts/dso ticket list` |
| Transition | `.claude/scripts/dso ticket transition <ID> <from> <to> --reason="..."` |
| Sync to remote | `.claude/scripts/dso ticket sync` |

Ticket prefix for this repo: **AKHIB**.

## DSO Workflows

| Skill | When to use |
|---|---|
| `/dso:brainstorm` | Turn an idea into a defined epic before implementation |
| `/dso:preplanning` | Decompose an epic into prioritized user stories with done definitions (set to **interactive** for this repo) |
| `/dso:implementation-plan` | Break a story into atomic TDD-driven tasks |
| `/dso:sprint` | Execute an epic via multi-agent orchestration |
| `/dso:fix-bug` | Classify and route a bug through investigation and fix |
| `/dso:validate-work` | Health check across code/CI/staging (CI gate is **N/A** here — outside repo) |
| `/dso:retro` | Periodic project health review, technical debt audit |

Merge strategy is **`direct`** (push directly to `main`) — `/dso:sprint` and merge tooling will not attempt PR-based gates.

## Rules

1. **Never edit `.tickets-tracker/` directly** — use the ticket commands above.
2. **Never bypass git hooks with `--no-verify`** without explicit user approval (no enforcement hooks installed today; this is a safeguard against future regressions).
3. **Never add a `.github/workflows/` file** to this repo without explicit user approval — CI lives in Azure DevOps.
4. **Bicep style**: prefer `.bicepparam` parameter files over JSON; keep one module per resource family under `modules/`.
5. **Secrets**: never inline secrets in `.bicep` or `.bicepparam`. Use Key Vault references or pipeline-injected parameters.

## Known Gaps

- No application test suite (the repo is intentionally IaC-only and "immature testing-wise" per onboarding).
- No pre-commit hooks installed today. If/when stricter enforcement is wanted, install `pre-commit` and add a Bicep-appropriate `.pre-commit-config.yaml`.
- See `.claude/docs/KNOWN-ISSUES.md` for incident history.
