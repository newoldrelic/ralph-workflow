# Ralph Workflow

Autonomous AI development using fresh context windows. Run complex multi-step projects unattended with human gates for quality control.

## TL;DR

Ralph is a bash loop that spawns fresh Claude instances for each iteration. Memory persists in files (prd.json, git), not in Claude's context window. This lets you tackle projects larger than a single context window.

## Quick Start

```bash
# Copy scripts to your project
cp ralph*.sh /path/to/your/project/
cd /path/to/your/project/
chmod +x ralph*.sh

# Follow the workflow below
```

## The Complete Workflow

```
thought/idea
    ↓
/prd skill → PRD.md (structured requirements)
    ↓
[HUMAN GATE 1] Review PRD, approve or request changes
    ↓
./ralph-prd-review.sh → PRD Review Loop (rotating personas)
    ↓
[HUMAN GATE 2] Review persona feedback, finalize prd.json
    ↓
git checkout -b feature/xyz (work on branch, not main)
    ↓
./ralph.sh → Implementation Loop (build features)
    ↓
[HUMAN GATE 3] Quick sanity check of implementation
    ↓
./ralph-code-review.sh → Code Review Loop (rotating personas)
    ↓
[HUMAN GATE 4] Final approval, create PR, merge to main
```

## Human Gates

| Gate | What You Review | Typical Time |
|------|-----------------|--------------|
| **Gate 1** | Is the PRD capturing what I actually want? | 5-10 min |
| **Gate 2** | Did personas raise valid concerns? Is prd.json ready? | 10-15 min |
| **Gate 3** | Does the implementation look roughly right? | 5 min |
| **Gate 4** | Is the polished code ready for production? | 15-30 min |

## Scripts

### ralph.sh - Implementation Loop

Builds features defined in prd.json. Each iteration:
1. Reads `@prd.json @progress.txt` for full context
2. Picks highest-priority incomplete story
3. Implements it, runs typecheck
4. Updates prd.json, commits
5. Exits (script loops with fresh context)

```bash
./ralph.sh 50  # max 50 iterations
```

### ralph-prd-review.sh - PRD Review

Reviews PRD before implementation with 4 rotating personas:
- **DEVELOPER** - Technical feasibility, story scoping
- **QA_ENGINEER** - Testability, verifiable criteria
- **SECURITY_ENGINEER** - Security implications, data privacy
- **USER_ADVOCATE** - User perspective, UX concerns

```bash
./ralph-prd-review.sh 12  # 2 full cycles through 4 personas
```

Output: `prd-review.md` with documented concerns.

### ralph-code-review.sh - Code Review

Reviews code after implementation with 6 rotating personas:
- **CODE_REVIEWER** - Bugs, edge cases, error handling
- **SECURITY_ENGINEER** - OWASP top 10, injection, auth
- **SYSTEM_ARCHITECT** - File structure, separation of concerns
- **FRONTEND_DESIGNER** - UI/UX, accessibility, responsiveness
- **QA_ENGINEER** - Tests, coverage, lint, build
- **PROJECT_MANAGER** - Acceptance criteria verification

Must pass 2 full cycles (12 consecutive iterations) with no issues.

```bash
./ralph-code-review.sh 25
```

## Required Files

Your project needs:

| File | Purpose |
|------|---------|
| `tasks/prd-*.md` | PRD file (glob pattern) |
| `prd.json` | Structured tasks with dependencies |
| `progress.txt` | Learning log across iterations |

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

### progress.txt Template

```markdown
# Ralph Progress Log
Started: [DATE]
Project: [PROJECT NAME]

## Codebase Patterns
(Patterns discovered during implementation)

---
```

## Installation

### Prerequisites

- Claude CLI installed: `npm install -g @anthropic-ai/claude-code`
- `/prd` skill installed at `~/.claude/skills/prd/`
- `/ralph-prd-converter` skill installed at `~/.claude/skills/ralph-prd-converter/`

### Setup for a New Project

```bash
# 1. Copy scripts
cp /path/to/ralph-workflow/ralph*.sh ./
chmod +x ralph*.sh

# 2. Create PRD
/prd "Your feature description"

# 3. Review PRD (GATE 1)
# Edit tasks/prd-*.md as needed

# 4. Run PRD review
./ralph-prd-review.sh 12

# 5. Review feedback (GATE 2)
# Check prd-review.md, update PRD if needed
/ralph-prd-converter tasks/prd-*.md

# 6. Initialize
git checkout -b feature/your-feature
cat > progress.txt << 'EOF'
# Ralph Progress Log
Started: $(date +%Y-%m-%d)
Project: Your Project

## Codebase Patterns
---
EOF

# 7. Run implementation
./ralph.sh 50

# 8. Sanity check (GATE 3)
npm run dev
git log --oneline -20

# 9. Run code review
./ralph-code-review.sh 25

# 10. Final approval (GATE 4)
git diff main...HEAD
gh pr create
```

## Why Fresh Context?

| Aspect | Accumulated Context | Fresh Context (Ralph) |
|--------|--------------------|-----------------------|
| Memory | In Claude's context | In files (prd.json, git) |
| Scale | Limited by context window | Unlimited iterations |
| Confusion | Context accumulates errors | Each iteration starts clean |
| State | Mixed in-memory + files | Files only |

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
- Production debugging

## Monitoring

While Ralph runs (in another terminal):

```bash
# Watch progress
tail -f ralph.log

# Watch commits
watch -n 5 'git log --oneline -10'

# Check story completion
cat prd.json | jq '.userStories[] | select(.passes == true) | .id'
```

## Cancelling

Press `Ctrl+C` in the terminal running the script.

## Credits

Based on the Ralph technique by [Geoffrey Huntley](https://ghuntley.com/ralph/).
