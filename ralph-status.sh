#!/bin/bash
# ralph-status.sh - Show status of all features in the manifest
# Usage: ./ralph-status.sh [manifest-path]
#
# Displays a formatted view of all features being tracked by Ralph.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m'

# Status color mapping
status_color() {
    case "$1" in
        "planned")         echo "$GRAY" ;;
        "prd_review")      echo "$CYAN" ;;
        "in_progress")     echo "$YELLOW" ;;
        "implemented")     echo "$MAGENTA" ;;
        "reviewing")       echo "$CYAN" ;;
        "complete")        echo "$GREEN" ;;
        "partial_release") echo "$GREEN" ;;
        "blocked")         echo "$RED" ;;
        "abandoned")       echo "$GRAY" ;;
        *)                 echo "$NC" ;;
    esac
}

# Status emoji mapping
status_emoji() {
    case "$1" in
        "planned")         echo "📋" ;;
        "prd_review")      echo "🔍" ;;
        "in_progress")     echo "🔧" ;;
        "implemented")     echo "✨" ;;
        "reviewing")       echo "🔬" ;;
        "complete")        echo "✅" ;;
        "partial_release") echo "📦" ;;
        "blocked")         echo "🚫" ;;
        "abandoned")       echo "🗑️" ;;
        *)                 echo "❓" ;;
    esac
}

# Find manifest
MANIFEST_FILE="${1:-ralph-manifest.json}"

if [ ! -f "$MANIFEST_FILE" ]; then
    echo -e "${RED}Error: Manifest not found: $MANIFEST_FILE${NC}"
    echo ""
    echo "To create a manifest, run /ralph-init to start a new feature,"
    echo "or create ralph-manifest.json manually."
    exit 1
fi

# Parse and display manifest
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📊 Ralph Feature Status${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Get project name from manifest
PROJECT=$(node -e "const m = require('./$MANIFEST_FILE'); console.log(m.project || 'Unknown Project')" 2>/dev/null || echo "Unknown Project")
echo -e "Project: ${GREEN}$PROJECT${NC}"
echo ""

# Count features by status
node -e "
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('$MANIFEST_FILE', 'utf8'));

const statusCounts = {};
manifest.features.forEach(f => {
    statusCounts[f.status] = (statusCounts[f.status] || 0) + 1;
});

console.log('Summary:');
Object.entries(statusCounts).forEach(([status, count]) => {
    console.log(\`  \${status}: \${count}\`);
});
" 2>/dev/null || echo "Unable to parse manifest"

echo ""
echo -e "${CYAN}Features:${NC}"
echo ""

# Display each feature
node -e "
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('$MANIFEST_FILE', 'utf8'));

manifest.features.forEach((f, i) => {
    // Status indicators
    const statusEmoji = {
        'planned': '📋',
        'prd_review': '🔍',
        'in_progress': '🔧',
        'implemented': '✨',
        'reviewing': '🔬',
        'complete': '✅',
        'partial_release': '📦',
        'blocked': '🚫',
        'abandoned': '🗑️'
    };

    const emoji = statusEmoji[f.status] || '❓';
    const date = f.lastUpdated ? new Date(f.lastUpdated).toLocaleDateString() : 'N/A';

    console.log(\`\${emoji} \${f.name}\`);
    console.log(\`   Status: \${f.status}\`);
    console.log(\`   PRD: \${f.prdFile}\`);
    console.log(\`   Branch: \${f.branch || 'N/A'}\`);
    console.log(\`   Updated: \${date}\`);
    if (f.notes) console.log(\`   Notes: \${f.notes}\`);
    if (f.releases && f.releases.length > 0) {
        console.log(\`   Releases: \${f.releases.length}\`);
    }
    console.log('');
});
" 2>/dev/null || echo "Unable to display features"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Commands:"
echo "  ralph.sh <prd.json> [iterations]           - Run implementation"
echo "  ralph-code-review.sh <prd.json> [iters]    - Run code review"
echo "  ralph-release.sh <prd.json> [commit]       - Record partial release"
echo "  ralph-status.sh [manifest]                 - Show this status"
