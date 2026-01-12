# Ralph Workflow

Autonomous AI development using fresh context windows. Run complex multi-step projects unattended with human gates for quality control.

## TL;DR

Ralph is a bash loop that spawns fresh Claude instances for each iteration. Memory persists in files (prd.json, git), not in Claude's context window. This lets you tackle projects larger than a single context window.

## Quick Start

```bash
# In any project, run the init skill (handles PRD + review + setup)
/ralph-init "Your feature description"

# Then exit and run implementation in a separate terminal
./ralph.sh 50

# When complete, run code review
/ralph-review
# Or for large projects:
./ralph-code-review.sh 25
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
├── Inits git branch, progress.txt
└── Says "Exit and run ./ralph.sh"
    ↓
./ralph.sh 50  (separate terminal - fresh context per iteration)
    ↓
/ralph-review or ./ralph-code-review.sh
    ↓
Human final approval → Merge
```

## Skills vs Scripts

| Tool | Context | Best For |
|------|---------|----------|
| `/ralph-init` | Single (accumulated) | Init phase - PRD creation, review, setup |
| `./ralph.sh` | Fresh per iteration | Implementation - could be 50+ iterations |
| `/ralph-review` | Single (accumulated) | Code review for smaller projects (<20 stories) |
| `./ralph-code-review.sh` | Fresh per iteration | Code review for larger projects |

**Why the split?**
- Init benefits from accumulated context (each persona sees what others found)
- Implementation needs fresh context (could exceed context window)
- Code review depends on project size

## Installation

### 1. Copy Scripts to Your Project

```bash
cp ~/Documents/GitHub/ralph-workflow/ralph*.sh ./
chmod +x ralph*.sh
```

### 2. Install Skills

The skills should be at:
- `~/.claude/skills/ralph-init/SKILL.md`
- `~/.claude/skills/ralph-review/SKILL.md`
- `~/.claude/skills/ralph-prd-converter/SKILL.md`

Copy from this repo or create manually.

### 3. Prerequisites

- Claude CLI: `npm install -g @anthropic-ai/claude-code`
- Existing skills that Ralph leverages:
  - `/prd` - PRD generation
  - `/frontend-design` - UI/UX review
  - `/test-driven-development` - Testing principles
  - `/verification-before-completion` - Acceptance criteria verification
  - `/requesting-code-review` - Code review principles
  - `/systematic-debugging` - Debugging approach

## Scripts

### ralph.sh - Implementation Loop

Each iteration:
1. Reads `@prd.json @progress.txt` for full context
2. Picks highest-priority incomplete story
3. Implements it, runs typecheck
4. Updates prd.json, commits
5. Exits (script loops with fresh context)

```bash
./ralph.sh 50  # max 50 iterations
```

### ralph-prd-review.sh - PRD Review (Fresh Context)

4 personas review PRD requirements:
- **DEVELOPER** - Technical feasibility, story scoping
- **QA_ENGINEER** - Testability, verifiable criteria
- **SECURITY_ENGINEER** - Security implications, OWASP
- **USER_ADVOCATE** - User perspective, UX

```bash
./ralph-prd-review.sh 12
```

### ralph-code-review.sh - Code Review (Fresh Context)

6 personas polish code, leveraging existing skills:
- **CODE_REVIEWER** - Uses `/requesting-code-review`, `/systematic-debugging`
- **SECURITY_ENGINEER** - OWASP Top 10 guide
- **SYSTEM_ARCHITECT** - Structure, separation of concerns
- **FRONTEND_DESIGNER** - Uses `/frontend-design`
- **QA_ENGINEER** - Uses `/test-driven-development`
- **PROJECT_MANAGER** - Uses `/verification-before-completion`

Must pass 2 full cycles (12 consecutive clean iterations).

```bash
./ralph-code-review.sh 25
```

## Skills

### /ralph-init

Full init workflow in a single context:
1. Create or review PRD
2. Run 4 persona PRD review (in-context)
3. Get human approval
4. Convert to prd.json
5. Initialize git branch and progress.txt
6. Output: "Exit and run ./ralph.sh"

```bash
/ralph-init "Add user authentication with OAuth"
/ralph-init existing  # Use existing PRD
```

### /ralph-review

In-context code review for smaller projects:
- Runs 6 personas in sequence
- Each persona fixes one issue at a time
- Continues until 2 clean rounds from all personas
- Accumulated context helps each persona see previous findings

```bash
/ralph-review
```

### /ralph-prd-converter

Converts PRD markdown to prd.json:
- Extracts user stories
- Determines dependencies
- Assigns priorities
- Creates structured JSON

```bash
/ralph-prd-converter tasks/prd-my-feature.md
```

## Required Files

| File | Purpose |
|------|---------|
| `tasks/prd-*.md` | PRD file (glob pattern) |
| `prd.json` | Structured tasks with dependencies |
| `progress.txt` | Learning log across iterations |
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
| **Gate 3** | After `./ralph.sh` | Implementation sanity check |
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
