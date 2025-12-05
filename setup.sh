#!/bin/bash

set -e

echo "=== Claude Code Setup ==="

# Install hooks dependencies
echo "Installing hooks dependencies..."
cd .claude/hooks
npm install
cd ../..

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps (run in Claude Code CLI):"
echo "  1. Add plugin marketplace:"
echo "     /plugin marketplace add ~/claude_setup/3rd_party/awesome-claude-code-plugins"
echo ""
echo "  2. Install plugins using:"
echo "     /plugin install <plugin-name>"
echo ""
echo "  See PLUGINS.md for the full list of recommended plugins."
