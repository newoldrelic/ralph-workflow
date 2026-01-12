---
name: wiggum-release
description: "Record a partial or full release of a feature. Tracks which stories shipped, updates manifest status. Use when merging to main."
---

# Wiggum Release

Record a partial or full release of a feature. Chief Wiggum tracks what's been shipped!

---

## Overview

Records releases in `ralph-manifest.json`:
- Tracks which stories were included
- Records commit hash and notes
- Updates feature status appropriately
- Supports partial releases (client wants some functionality early)

---

## Usage

```bash
/wiggum-release
/wiggum-release prd.json
/wiggum-release prd.json "Released auth stories for client demo"
```

---

## Arguments

- **prd.json path** (optional): Path to prd.json file. Defaults to `prd.json` in current directory.
- **notes** (optional): Description of what's being released and why.

---

## Process

### Step 1: Read Current State

Read the prd.json to determine:
- Total number of stories
- Which stories have `passes: true`
- Feature name and branch

### Step 2: Determine Release Type

- **Full release**: All stories have `passes: true`
- **Partial release**: Some stories complete, others pending

### Step 3: Get Release Details

Ask user (if not provided):
- Commit hash (default: current HEAD)
- Release notes

### Step 4: Update Manifest

Add release record to `ralph-manifest.json`:

```json
{
  "date": "2026-01-12T10:00:00Z",
  "commit": "abc123def",
  "type": "full|partial",
  "storiesIncluded": ["US-001", "US-002"],
  "notes": "Release notes here"
}
```

Update feature status:
- Full release → `complete`
- Partial release → `partial_release`

### Step 5: Confirm

Display summary:

```
## Release Recorded ✅

**Type:** Partial Release
**Commit:** abc123def
**Stories included:** 3 of 8

### Included:
- ✓ US-001: User login
- ✓ US-002: User registration
- ✓ US-003: Password reset

### Remaining:
- ○ US-004: OAuth integration
- ○ US-005: Two-factor auth
...

To continue implementation:
  ralph.sh prd.json 50
```

---

## Example: Full Release

```
/wiggum-release prd.json "v1.0 - All auth features complete"

## Release Recorded ✅

**Type:** Full Release
**Commit:** def456ghi
**Stories included:** 8 of 8

All stories complete! Feature ready for final merge.

Next steps:
- Create PR: gh pr create
- Merge to main
```

---

## Example: Partial Release

```
/wiggum-release prd.json "Client needs login ASAP, rest can wait"

## Release Recorded ✅

**Type:** Partial Release
**Commit:** abc123def
**Stories included:** 3 of 8

### Included:
- ✓ US-001: User login
- ✓ US-002: Session management
- ✓ US-003: Logout

### Remaining:
- ○ US-004: Password reset
- ○ US-005: OAuth
...

Feature status updated to: partial_release

To continue with remaining stories:
  ralph.sh prd.json 50
```

---

## Alternative

For instant terminal execution without spawning Claude:
```bash
ralph-release.sh prd.json [commit] [notes]
```
