---
name: wiggum-status
description: "Show status of all features in ralph-manifest.json. Displays progress, releases, and what's next across all tracked features."
---

# Wiggum Status

Display the status of all features being tracked in the current project's manifest. Chief Wiggum keeps an eye on everything!

---

## Overview

Shows a formatted view of all features in `ralph-manifest.json`:
- Feature name and status
- Associated PRD file and branch
- Release history
- Summary counts by status

---

## Usage

```bash
/wiggum-status
/wiggum-status ralph-manifest.json
```

---

## Process

1. Read `ralph-manifest.json` (or specified manifest file)
2. Display formatted status for each feature
3. Show summary counts

---

## Output Format

```
## Wiggum Feature Status

**Project:** My Project

### Summary
- complete: 2
- in_progress: 1
- planned: 1

### Features

✅ **User Authentication** (complete)
   - PRD: prd.json
   - Branch: feature/auth
   - Updated: 2026-01-11
   - Releases: 1 (full)

📦 **Product Catalog** (partial_release)
   - PRD: features/catalog-prd.json
   - Branch: feature/catalog
   - Updated: 2026-01-12
   - Releases: 1 (partial - 2/5 stories)
   - Notes: Client requested early release

🔧 **Payment Integration** (in_progress)
   - PRD: features/payment-prd.json
   - Branch: feature/payments
   - Updated: 2026-01-12
   - Notes: Working on Stripe integration

📋 **Email Notifications** (planned)
   - PRD: features/email-prd.json
   - Branch: feature/email
```

---

## Status Icons

| Status | Icon | Meaning |
|--------|------|---------|
| planned | 📋 | PRD created, not started |
| prd_review | 🔍 | Under PRD review |
| in_progress | 🔧 | Implementation running |
| implemented | ✨ | Implementation complete, awaiting review |
| reviewing | 🔬 | Code review in progress |
| complete | ✅ | All done, ready for merge |
| partial_release | 📦 | Some stories released early |
| blocked | 🚫 | Needs human intervention |
| abandoned | 🗑️ | Cancelled |

---

## If No Manifest Found

If `ralph-manifest.json` doesn't exist, inform the user:

```
No ralph-manifest.json found in this project.

To start tracking features, run:
  /wiggum-init "Your feature description"

Or create a manifest manually with ralph-manifest-add.sh
```

---

## Alternative

For instant terminal display without spawning Claude:
```bash
ralph-status.sh
```
