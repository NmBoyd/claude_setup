#!/bin/bash

set -e

echo "=== Claude Code Setup ==="

# Install hooks dependencies
echo "Installing hooks dependencies..."
cd .claude/hooks
npm install
cd ../..

echo ""
echo "=== Installing Plugins ==="
echo ""

# Add plugin marketplace
echo "Adding plugin marketplace..."
claude "/plugin marketplace add ~/claude_setup/3rd_party/awesome-claude-code-plugins"

# List of all plugins to install
plugins=(
    "agent-sdk-dev"
    "pr-review-toolkit"
    "commit-commands"
    "feature-dev"
    "security-guidance"
    "ai-engineer"
    "api-integration-specialist"
    "backend-architect"
    "code-architect"
    "desktop-app-dev"
    "enterprise-integrator-architect"
    "flutter-mobile-app-dev"
    "frontend-developer"
    "mobile-app-builder"
    "project-curator"
    "python-expert"
    "rapid-prototyper"
    "react-native-dev"
    "vision-specialist"
    "web-dev"
    "api-tester"
    "bug-detective"
    "code-review"
    "code-review-assistant"
    "code-reviewer"
    "database-performance-optimizer"
    "debug-session"
    "debugger"
    "double-check"
    "optimize"
    "performance-benchmarker"
    "refractor"
    "test-file"
    "test-results-analyzer"
    "test-writer-fixer"
    "unit-test-generator"
    "deployment-engineer"
    "devops-automator"
    "infrastructure-maintainer"
    "monitoring-observability-specialist"
    "n8n-workflow-builder"
    "angelos-symbo"
    "ceo-quality-controller-agent"
    "claude-desktop-extension"
    "lyra"
    "model-context-protocol-mcp-expert"
    "problem-solver-specialist"
    "studio-coach"
    "ultrathink"
    "analyze-codebase"
    "changelog-generator"
    "codebase-documenter"
    "context7-docs-fetcher"
    "documentation-generator"
    "generate-api-docs"
    "openapi-expert"
    "update-claudemd"
    "analyze-issue"
    "bug-fix"
    "commit"
    "create-pr"
    "create-pull-request"
    "create-worktrees"
    "fix-github-issue"
    "fix-issue"
    "fix-pr"
    "github-issue-fix"
    "husky"
    "pr-issue-resolve"
    "pr-review"
    "update-branch-name"
    "ai-ethics-governance-specialist"
    "audit"
    "compliance-automation-specialist"
    "data-privacy-engineer"
    "enterprise-security-reviewer"
    "legal-advisor"
    "legal-compliance-checker"
    "discuss"
    "explore"
    "plan"
    "planning-prd-agent"
    "prd-specialist"
    "project-shipper"
    "sprint-prioritizer"
    "studio-producer"
    "tool-evaluator"
    "workflow-optimizer"
)

# Install each plugin using claude --print (non-interactive, exits after command)
total=${#plugins[@]}
current=0

for plugin in "${plugins[@]}"; do
    current=$((current + 1))
    echo "[$current/$total] Installing $plugin..."
    claude "/plugin install $plugin" 2>/dev/null || echo "  Warning: Failed to install $plugin"
done

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Installed $total plugins."
