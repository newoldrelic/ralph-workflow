#!/bin/bash
# ralph-manifest-add.sh - Add a feature to the manifest
# Usage: ./ralph-manifest-add.sh <name> <prd-file> <branch> [status]
#
# Creates the manifest if it doesn't exist, then adds the feature.
# Used by /ralph-init skill during initialization.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Argument handling
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo -e "${RED}Error: Missing required arguments${NC}"
    echo "Usage: ralph-manifest-add.sh <name> <prd-file> <branch> [status]"
    echo ""
    echo "Arguments:"
    echo "  name      - Feature name (e.g., 'User Authentication')"
    echo "  prd-file  - Path to prd.json (e.g., 'prd.json' or 'features/auth-prd.json')"
    echo "  branch    - Git branch name (e.g., 'feature/auth')"
    echo "  status    - Optional initial status (default: 'planned')"
    echo ""
    echo "Valid statuses:"
    echo "  planned, prd_review, in_progress, implemented, reviewing,"
    echo "  complete, partial_release, blocked, abandoned"
    exit 1
fi

FEATURE_NAME="$1"
PRD_FILE="$2"
BRANCH="$3"
STATUS="${4:-planned}"
MANIFEST_FILE="ralph-manifest.json"

# Get project name from git or directory
PROJECT_NAME=$(basename "$(pwd)")
if [ -f "package.json" ]; then
    PKG_NAME=$(node -e "console.log(require('./package.json').name || '')" 2>/dev/null)
    if [ -n "$PKG_NAME" ]; then
        PROJECT_NAME="$PKG_NAME"
    fi
fi

# Create manifest if it doesn't exist
if [ ! -f "$MANIFEST_FILE" ]; then
    echo -e "${CYAN}Creating new manifest...${NC}"
    cat > "$MANIFEST_FILE" << EOF
{
  "project": "$PROJECT_NAME",
  "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "features": []
}
EOF
fi

# Add feature to manifest
node -e "
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('$MANIFEST_FILE', 'utf8'));

// Check if feature with this prd already exists
const existing = manifest.features.find(f => f.prdFile === '$PRD_FILE');
if (existing) {
    console.log('Feature already exists, updating...');
    existing.name = '$FEATURE_NAME';
    existing.branch = '$BRANCH';
    existing.status = '$STATUS';
    existing.lastUpdated = new Date().toISOString();
} else {
    console.log('Adding new feature...');
    manifest.features.push({
        name: '$FEATURE_NAME',
        prdFile: '$PRD_FILE',
        branch: '$BRANCH',
        status: '$STATUS',
        created: new Date().toISOString(),
        lastUpdated: new Date().toISOString(),
        notes: '',
        releases: []
    });
}

fs.writeFileSync('$MANIFEST_FILE', JSON.stringify(manifest, null, 2));
console.log('Manifest updated.');
"

echo -e "${GREEN}✅ Feature added to manifest${NC}"
echo ""
echo "Feature: $FEATURE_NAME"
echo "PRD: $PRD_FILE"
echo "Branch: $BRANCH"
echo "Status: $STATUS"
echo ""
echo "View all features: ralph-status.sh"
