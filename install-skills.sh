#!/bin/bash
# install-skills.sh - Install Ralph workflow skills to Claude Code
#
# This creates symlinks from ~/.claude/skills/ to the skills in this repo.
# Benefits: Skills stay in sync with repo updates (just git pull).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Installing Ralph workflow skills...${NC}"

# Create skills directory if it doesn't exist
mkdir -p "$SKILLS_DIR"

# Skills to install (wiggum-* and prd)
SKILL_PATTERNS=("wiggum-*" "prd")

for pattern in "${SKILL_PATTERNS[@]}"; do
    for skill in "$SCRIPT_DIR/skills/"$pattern; do
        [ -e "$skill" ] || continue  # Skip if no match

        skill_name=$(basename "$skill")
        target="$SKILLS_DIR/$skill_name"

        if [ -L "$target" ]; then
            echo "  Updating symlink: $skill_name"
            rm "$target"
        elif [ -d "$target" ]; then
            echo -e "${YELLOW}  Warning: $skill_name exists as directory, backing up...${NC}"
            mv "$target" "$target.backup"
        fi

        ln -s "$skill" "$target"
        echo -e "${GREEN}  ✓ Linked: $skill_name${NC}"
    done
done

echo ""
echo -e "${GREEN}Skills installed!${NC}"
echo ""
echo "Available commands:"
echo "  /prd            - Generate a PRD for a new feature"
echo "  /wiggum-prd     - Create PRD with validation, persona review, and setup"
echo "  /wiggum-review  - Run 6-persona code review"
echo "  /wiggum-status  - Show feature status"
echo "  /wiggum-release - Record a release"
echo ""
echo "Don't forget to add scripts to PATH:"
echo "  export PATH=\"\$PATH:$SCRIPT_DIR\""
