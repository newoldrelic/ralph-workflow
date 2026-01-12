# Ralph Workflow

Autonomous AI development using fresh context windows. Run complex multi-step projects unattended with human gates for quality control.

Based on the [Ralph technique by Geoffrey Huntley](https://ghuntley.com/ralph/). All scripts and skills in this repo were built in-house.

## TL;DR

Ralph is a bash loop that spawns fresh Claude instances for each iteration. Memory persists in files (prd.json, git), not in Claude's context window. This lets you tackle projects larger than a single context window.

## Why This Approach?

### The Problem
- Claude's context window is finite - complex projects exceed it
- Accumulated context leads to confusion and degraded performance
- Long sessions lose focus on what matters

### The Solution: Fresh Context Per Iteration
| Aspect | Traditional | Ralph Workflow |
|--------|-------------|----------------|
| Context | Accumulates until overflow | Fresh each iteration |
| Memory | In Claude's context | In files (prd.json, git) |
| Scale | Limited by context window | Unlimited iterations |
| Focus | Degrades over time | Sharp every iteration |

### Key Advantages

**1. Unlimited Project Scale**
- Run 50+ iterations without context overflow
- Each iteration reads full state from files
- Projects that would be impossible in one session become routine

**2. Unattended Execution**
- Start `ralph.sh` and walk away
- Run overnight for large features
- Check progress via `ralph.log` and git commits

**3. Quality Through Human Gates**
- 4 checkpoints prevent building the wrong thing
- PRD review catches issues before implementation
- Code review ensures production quality

**4. Multi-Persona Review**
- 4 personas review PRD (Developer, QA, Security, User Advocate)
- 6 personas review code (Code, Security, Architecture, Frontend, QA, PM)
- Different perspectives catch different issues

**5. Partial Release Support**
- Client needs something early? Release completed stories
- Manifest tracks what shipped and what's pending
- Continue implementation after partial release

**6. Accumulated Context Where It Helps**
- Init phase: personas see what others found
- Review phase: fixes inform subsequent checks
- Implementation: fresh context avoids confusion

**7. Easy Multi-Machine Setup**
- Clone repo, run install script, add to PATH
- Symlinked skills update with `git pull`
- Same workflow on laptop, desktop, CI

## Installation

### 1. Clone the Repo

```bash
git clone https://github.com/newoldrelic/ralph-workflow.git ~/Documents/GitHub/ralph-workflow
```

### 2. Install Skills

The install script creates symlinks so skills stay in sync with repo updates:

```bash
~/Documents/GitHub/ralph-workflow/install-skills.sh
```

### 3. Add Scripts to PATH

Add to `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="$PATH:$HOME/Documents/GitHub/ralph-workflow"
```

Then reload:
```bash
source ~/.zshrc
```

### 4. Prerequisites

- Claude CLI: `npm install -g @anthropic-ai/claude-code`
- Node.js (for manifest JSON manipulation)

## Quick Start

```bash
# In any project, run the init skill (handles PRD + review + setup)
/wiggum-init "Your feature description"

# Then exit and run implementation in a separate terminal
ralph.sh prd.json 50

# When complete, run code review
/wiggum-review
# Or for large projects:
ralph-code-review.sh prd.json 25

# View status of all features
/wiggum-status
```

## The Complete Workflow

```
/wiggum-init "feature description"
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
/wiggum-review or ralph-code-review.sh prd.json
    ↓
Human final approval → Merge
    ↓
/wiggum-release prd.json  (record the release)
```

## Skills (Chief Wiggum oversees Ralph!)

| Skill | Description |
|-------|-------------|
| `/wiggum-init` | Initialize feature: PRD creation, 4-persona review, prd.json setup |
| `/wiggum-review` | In-context 6-persona code review (for projects <20 stories) |
| `/wiggum-status` | Show status of all tracked features |
| `/wiggum-release` | Record partial or full release |

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
| `/wiggum-init` | Single (accumulated) | Init phase - PRD creation, review, setup |
| `ralph.sh` | Fresh per iteration | Implementation - could be 50+ iterations |
| `/wiggum-review` | Single (accumulated) | Code review for smaller projects (<20 stories) |
| `ralph-code-review.sh` | Fresh per iteration | Code review for larger projects |

**Why the split?**
- Init benefits from accumulated context (each persona sees what others found)
- Implementation needs fresh context (could exceed context window)
- Code review depends on project size

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
| **Gate 1** | In `/wiggum-init` | PRD captures what you want? |
| **Gate 2** | In `/wiggum-init` | Persona feedback acceptable? |
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
/wiggum-status
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

**Inspiration:** The Ralph technique concept by [Geoffrey Huntley](https://ghuntley.com/ralph/)

**Built in-house:** All scripts and Wiggum skills in this repo
