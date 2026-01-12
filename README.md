# Ralph Workflow

Autonomous AI development using fresh context windows. Run complex multi-step projects unattended with human gates for quality control.

## TL;DR

Ralph is a bash loop that spawns fresh Claude instances for each iteration. Memory persists in files (prd.json, git), not in Claude's context window. This lets you tackle projects larger than a single context window.

## Quick Start

```bash
# Add to PATH (recommended - add to ~/.zshrc or ~/.bashrc)
export PATH="$PATH:$HOME/Documents/GitHub/ralph-workflow"

# In any project, run the init skill (handles PRD + review + setup)
/ralph-init "Your feature description"

# Then exit and run implementation in a separate terminal
ralph.sh prd.json 50

# When complete, run code review
/ralph-review
# Or for large projects:
ralph-code-review.sh prd.json 25

# View status of all features
ralph-status.sh
```

## The Complete Workflow

```
/ralph-init "feature description"
    ↓
[Single Context - Skill]
├── Creates PRD (asks clarifying questions)
├── Runs PRD review (4 personas in-context)
├── Gets human approval
├── Converts to prd.json
├── Inits git branch, progress.txt, manifest
└── Says "Exit and run ralph.sh prd.json"
    ↓
ralph.sh prd.json 50  (separate terminal - fresh context per iteration)
    ↓
/ralph-review or ralph-code-review.sh prd.json
    ↓
Human final approval → Merge
    ↓
ralph-release.sh prd.json  (record the release)
```

## Scripts

All scripts take explicit file arguments for clarity:

| Script | Usage | Purpose |
|--------|-------|---------|
| `ralph.sh` | `ralph.sh <prd.json> [iterations]` | Implementation loop (fresh context) |
| `ralph-prd-review.sh` | `ralph-prd-review.sh <prd.md> [iterations]` | PRD review with 4 personas |
| `ralph-code-review.sh` | `ralph-code-review.sh <prd.json> [iterations]` | Code review with 6 personas |
| `ralph-status.sh` | `ralph-status.sh [manifest]` | Show all feature statuses |
| `ralph-release.sh` | `ralph-release.sh <prd.json> [commit] [notes]` | Record partial/full release |
| `ralph-manifest-add.sh` | `ralph-manifest-add.sh <name> <prd> <branch> [status]` | Add feature to manifest |

### ralph.sh - Implementation Loop

Each iteration:
1. Reads `prd.json` and `progress.txt` for full context
2. Picks highest-priority incomplete story
3. Implements it, runs typecheck
4. Updates prd.json, commits
5. Exits (script loops with fresh context)

On completion, auto-suggests review type based on story count.

```bash
ralph.sh prd.json 50  # max 50 iterations
```

### ralph-prd-review.sh - PRD Review

4 personas review PRD requirements:
- **DEVELOPER** - Technical feasibility, story scoping
- **QA_ENGINEER** - Testability, verifiable criteria
- **SECURITY_ENGINEER** - Security implications, OWASP
- **USER_ADVOCATE** - User perspective, UX

```bash
ralph-prd-review.sh tasks/prd-my-feature.md 12
```

### ralph-code-review.sh - Code Review

6 personas polish code, leveraging existing skills:
- **CODE_REVIEWER** - Uses `/requesting-code-review`, `/systematic-debugging`
- **SECURITY_ENGINEER** - OWASP Top 10 guide
- **SYSTEM_ARCHITECT** - Structure, separation of concerns
- **FRONTEND_DESIGNER** - Uses `/frontend-design`
- **QA_ENGINEER** - Uses `/test-driven-development`
- **PROJECT_MANAGER** - Uses `/verification-before-completion`

Must pass 2 full cycles (12 consecutive clean iterations).

```bash
ralph-code-review.sh prd.json 25
```

### ralph-status.sh - Feature Status

View all features being tracked:

```bash
ralph-status.sh

# Output:
# 📊 Ralph Feature Status
# Project: My Project
#
# ✅ User Authentication - complete
# 📦 Product Catalog - partial_release
# 🔧 Payment Integration - in_progress
# 📋 Email Notifications - planned
```

### ralph-release.sh - Record Releases

Record when stories are released, even if the feature isn't complete (partial release):

```bash
# Full release (all stories complete)
ralph-release.sh prd.json

# Partial release with notes
ralph-release.sh prd.json abc123 "Released auth stories for client demo"
```

## Skills vs Scripts

| Tool | Context | Best For |
|------|---------|----------|
| `/ralph-init` | Single (accumulated) | Init phase - PRD creation, review, setup |
| `ralph.sh` | Fresh per iteration | Implementation - could be 50+ iterations |
| `/ralph-review` | Single (accumulated) | Code review for smaller projects (<20 stories) |
| `ralph-code-review.sh` | Fresh per iteration | Code review for larger projects |

**Why the split?**
- Init benefits from accumulated context (each persona sees what others found)
- Implementation needs fresh context (could exceed context window)
- Code review depends on project size

## Installation

### 1. Add Scripts to PATH (Recommended)

```bash
# Add to ~/.zshrc or ~/.bashrc
export PATH="$PATH:$HOME/Documents/GitHub/ralph-workflow"

# Reload shell
source ~/.zshrc
```

### 2. Skills Location

Skills should be at:
- `~/.claude/skills/ralph-init/SKILL.md`
- `~/.claude/skills/ralph-review/SKILL.md`
- `~/.claude/skills/ralph-prd-converter/SKILL.md`

### 3. Prerequisites

- Claude CLI: `npm install -g @anthropic-ai/claude-code`
- Node.js (for manifest JSON manipulation)
- Existing skills that Ralph leverages:
  - `/prd` - PRD generation
  - `/frontend-design` - UI/UX review
  - `/test-driven-development` - Testing principles
  - `/verification-before-completion` - Acceptance criteria verification
  - `/requesting-code-review` - Code review principles
  - `/systematic-debugging` - Debugging approach

## Manifest Tracking

Ralph uses `ralph-manifest.json` to track multiple features:

```json
{
  "project": "My Project",
  "features": [
    {
      "name": "User Authentication",
      "prdFile": "prd.json",
      "branch": "feature/auth",
      "status": "complete",
      "releases": [
        {
          "date": "2026-01-12T10:00:00Z",
          "commit": "abc123",
          "type": "full",
          "storiesIncluded": ["US-001", "US-002"]
        }
      ]
    }
  ]
}
```

**Valid statuses:**
- `planned` - PRD created, not started
- `prd_review` - Under PRD review
- `in_progress` - Implementation running
- `implemented` - Implementation complete, awaiting review
- `reviewing` - Code review in progress
- `complete` - All done, ready for merge
- `partial_release` - Some stories released early
- `blocked` - Needs human intervention
- `abandoned` - Cancelled

## Required Files

| File | Purpose |
|------|---------|
| `tasks/prd-*.md` | PRD file (markdown) |
| `prd.json` | Structured tasks with dependencies |
| `progress.txt` | Learning log across iterations |
| `ralph-manifest.json` | Tracks all features |
| `prd-review.md` | PRD review feedback (generated) |

### prd.json Structure

```json
{
  "project": "Project Name",
  "branchName": "feature/branch-name",
  "description": "Feature description",
  "userStories": [
    {
      "id": "US-001",
      "title": "Story title",
      "description": "As a [user], I want...",
      "acceptanceCriteria": ["criterion 1", "criterion 2"],
      "priority": 1,
      "dependsOn": [],
      "passes": false,
      "notes": ""
    }
  ]
}
```

## Human Gates

| Gate | Where | What You Review |
|------|-------|-----------------|
| **Gate 1** | In `/ralph-init` | PRD captures what you want? |
| **Gate 2** | In `/ralph-init` | Persona feedback acceptable? |
| **Gate 3** | After `ralph.sh` | Implementation sanity check |
| **Gate 4** | After review | Final approval, merge |

## Monitoring

While Ralph runs:

```bash
# Watch progress
tail -f ralph.log

# Watch commits
watch -n 5 'git log --oneline -10'

# Check story completion
cat prd.json | jq '.userStories[] | select(.passes == true) | .id'

# View all features
ralph-status.sh
```

## When to Use Ralph

**Good for:**
- Features with 5+ distinct implementation steps
- Work you want to run unattended (overnight)
- Greenfield projects with clear requirements
- Tasks with automatic verification (tests, typecheck)

**Not good for:**
- Quick fixes (1-2 file changes)
- Exploratory work without clear requirements
- Tasks requiring frequent human judgment

## Credits

Based on the Ralph technique by [Geoffrey Huntley](https://ghuntley.com/ralph/).
