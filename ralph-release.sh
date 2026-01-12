#!/bin/bash
# ralph-release.sh - Record a partial or full release of a feature
# Usage: ./ralph-release.sh <prd.json> [commit-hash] [notes]
#
# Records when stories from a feature are merged/released, even if not complete.
# Useful when a client wants some functionality released early.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Argument handling
if [ -z "$1" ]; then
    echo -e "${RED}Error: prd.json path required${NC}"
    echo "Usage: ralph-release.sh <prd.json> [commit-hash] [notes]"
    echo ""
    echo "Examples:"
    echo "  ralph-release.sh prd.json"
    echo "  ralph-release.sh prd.json abc123 'Released auth stories only'"
    exit 1
fi

PRD_FILE="$1"
COMMIT_HASH="${2:-$(git rev-parse HEAD 2>/dev/null || echo 'unknown')}"
RELEASE_NOTES="${3:-}"

# Validate prd.json exists
if [ ! -f "$PRD_FILE" ]; then
    echo -e "${RED}Error: PRD file not found: $PRD_FILE${NC}"
    exit 1
fi

# Get working directory from PRD file location
WORK_DIR="$(cd "$(dirname "$PRD_FILE")" && pwd)"
PRD_BASENAME="$(basename "$PRD_FILE")"
MANIFEST_FILE="$WORK_DIR/ralph-manifest.json"

# Check manifest exists
if [ ! -f "$MANIFEST_FILE" ]; then
    echo -e "${RED}Error: Manifest not found: $MANIFEST_FILE${NC}"
    echo "Run /ralph-init first to create a manifest."
    exit 1
fi

# Get story completion status from prd.json
COMPLETED_STORIES=$(node -e "
const fs = require('fs');
const prd = JSON.parse(fs.readFileSync('$PRD_FILE', 'utf8'));
const completed = prd.userStories.filter(s => s.passes === true).map(s => s.id);
console.log(JSON.stringify(completed));
" 2>/dev/null || echo "[]")

TOTAL_STORIES=$(node -e "
const fs = require('fs');
const prd = JSON.parse(fs.readFileSync('$PRD_FILE', 'utf8'));
console.log(prd.userStories.length);
" 2>/dev/null || echo "0")

COMPLETED_COUNT=$(node -e "console.log($COMPLETED_STORIES.length)" 2>/dev/null || echo "0")

echo -e "${CYAN}📦 Recording Release${NC}"
echo "PRD file: $PRD_FILE"
echo "Commit: $COMMIT_HASH"
echo "Stories completed: $COMPLETED_COUNT / $TOTAL_STORIES"
echo "---"

# Determine release type
if [ "$COMPLETED_COUNT" -eq "$TOTAL_STORIES" ]; then
    RELEASE_TYPE="full"
    NEW_STATUS="complete"
    echo -e "${GREEN}Release type: FULL (all stories complete)${NC}"
else
    RELEASE_TYPE="partial"
    NEW_STATUS="partial_release"
    echo -e "${YELLOW}Release type: PARTIAL ($COMPLETED_COUNT of $TOTAL_STORIES stories)${NC}"
fi

# Update manifest with release info
node -e "
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('$MANIFEST_FILE', 'utf8'));
const feature = manifest.features.find(f => f.prdFile === '$PRD_BASENAME');

if (feature) {
    // Add release record
    if (!feature.releases) feature.releases = [];
    feature.releases.push({
        date: new Date().toISOString(),
        commit: '$COMMIT_HASH',
        type: '$RELEASE_TYPE',
        storiesIncluded: $COMPLETED_STORIES,
        notes: '$RELEASE_NOTES' || 'Release recorded'
    });

    // Update status
    feature.status = '$NEW_STATUS';
    feature.lastUpdated = new Date().toISOString();

    fs.writeFileSync('$MANIFEST_FILE', JSON.stringify(manifest, null, 2));
    console.log('Manifest updated successfully');
} else {
    console.log('Warning: Feature not found in manifest');
}
" 2>/dev/null

echo ""
echo -e "${GREEN}✅ Release recorded${NC}"
echo ""

# Show what was included
echo "Stories included in this release:"
node -e "
const stories = $COMPLETED_STORIES;
stories.forEach(id => console.log('  ✓ ' + id));
" 2>/dev/null

# Show what's remaining if partial
if [ "$RELEASE_TYPE" = "partial" ]; then
    echo ""
    echo "Stories remaining:"
    node -e "
    const fs = require('fs');
    const prd = JSON.parse(fs.readFileSync('$PRD_FILE', 'utf8'));
    const remaining = prd.userStories.filter(s => s.passes !== true);
    remaining.forEach(s => console.log('  ○ ' + s.id + ': ' + s.title));
    " 2>/dev/null
    echo ""
    echo -e "${YELLOW}Note: Remaining stories can continue with:${NC}"
    echo "  ralph.sh $PRD_FILE"
fi

echo ""
echo "View all features with: ralph-status.sh"
