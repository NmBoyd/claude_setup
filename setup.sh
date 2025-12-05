#!/bin/bash

set -e

echo "=== Claude Code Setup ==="

# Install hooks dependencies
echo "Installing hooks dependencies..."
cd .claude/hooks
npm install
cd ../..

# =============================================================================
# Plugin Marketplace Setup
# =============================================================================
echo ""
echo "=== Setting up Plugin Marketplace ==="

# Add the awesome-claude-code-plugins marketplace
# Note: Adjust the path/repo based on your setup
echo "Adding plugin marketplace..."
/plugin marketplace add 3rd_party/awesome-claude-code-plugins 2>/dev/null || echo "Marketplace may already be added"

# =============================================================================
# Official Claude Code Plugins
# =============================================================================
echo ""
echo "=== Installing Official Claude Code Plugins ==="
OFFICIAL_PLUGINS=(
    "agent-sdk-dev"
    "pr-review-toolkit"
    "commit-commands"
    "feature-dev"
    "security-guidance"
)
for plugin in "${OFFICIAL_PLUGINS[@]}"; do
    echo "Installing $plugin..."
    /plugin install "$plugin" 2>/dev/null || echo "  - $plugin may already be installed or unavailable"
done

# =============================================================================
# Development Engineering
# =============================================================================
echo ""
echo "=== Installing Development Engineering Plugins ==="
DEV_PLUGINS=(
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
)
for plugin in "${DEV_PLUGINS[@]}"; do
    echo "Installing $plugin..."
    /plugin install "$plugin" 2>/dev/null || echo "  - $plugin may already be installed or unavailable"
done

# =============================================================================
# Code Quality & Testing
# =============================================================================
echo ""
echo "=== Installing Code Quality & Testing Plugins ==="
QUALITY_PLUGINS=(
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
)
for plugin in "${QUALITY_PLUGINS[@]}"; do
    echo "Installing $plugin..."
    /plugin install "$plugin" 2>/dev/null || echo "  - $plugin may already be installed or unavailable"
done

# =============================================================================
# Automation & DevOps
# =============================================================================
echo ""
echo "=== Installing Automation & DevOps Plugins ==="
DEVOPS_PLUGINS=(
    "deployment-engineer"
    "devops-automator"
    "infrastructure-maintainer"
    "monitoring-observability-specialist"
    "n8n-workflow-builder"
)
for plugin in "${DEVOPS_PLUGINS[@]}"; do
    echo "Installing $plugin..."
    /plugin install "$plugin" 2>/dev/null || echo "  - $plugin may already be installed or unavailable"
done

# =============================================================================
# Workflow Orchestration
# =============================================================================
echo ""
echo "=== Installing Workflow Orchestration Plugins ==="
WORKFLOW_PLUGINS=(
    "angelos-symbo"
    "ceo-quality-controller-agent"
    "claude-desktop-extension"
    "lyra"
    "model-context-protocol-mcp-expert"
    "problem-solver-specialist"
    "studio-coach"
    "ultrathink"
)
for plugin in "${WORKFLOW_PLUGINS[@]}"; do
    echo "Installing $plugin..."
    /plugin install "$plugin" 2>/dev/null || echo "  - $plugin may already be installed or unavailable"
done

# =============================================================================
# Documentation
# =============================================================================
echo ""
echo "=== Installing Documentation Plugins ==="
DOC_PLUGINS=(
    "analyze-codebase"
    "changelog-generator"
    "codebase-documenter"
    "context7-docs-fetcher"
    "documentation-generator"
    "generate-api-docs"
    "openapi-expert"
    "update-claudemd"
)
for plugin in "${DOC_PLUGINS[@]}"; do
    echo "Installing $plugin..."
    /plugin install "$plugin" 2>/dev/null || echo "  - $plugin may already be installed or unavailable"
done

# =============================================================================
# Git Workflow
# =============================================================================
echo ""
echo "=== Installing Git Workflow Plugins ==="
GIT_PLUGINS=(
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
)
for plugin in "${GIT_PLUGINS[@]}"; do
    echo "Installing $plugin..."
    /plugin install "$plugin" 2>/dev/null || echo "  - $plugin may already be installed or unavailable"
done

# =============================================================================
# Security, Compliance & Legal
# =============================================================================
echo ""
echo "=== Installing Security, Compliance & Legal Plugins ==="
SECURITY_PLUGINS=(
    "ai-ethics-governance-specialist"
    "audit"
    "compliance-automation-specialist"
    "data-privacy-engineer"
    "enterprise-security-reviewer"
    "legal-advisor"
    "legal-compliance-checker"
)
for plugin in "${SECURITY_PLUGINS[@]}"; do
    echo "Installing $plugin..."
    /plugin install "$plugin" 2>/dev/null || echo "  - $plugin may already be installed or unavailable"
done

# =============================================================================
# Project & Product Management
# =============================================================================
echo ""
echo "=== Installing Project & Product Management Plugins ==="
PM_PLUGINS=(
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
for plugin in "${PM_PLUGINS[@]}"; do
    echo "Installing $plugin..."
    /plugin install "$plugin" 2>/dev/null || echo "  - $plugin may already be installed or unavailable"
done

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "=== Setup Complete ==="
echo ""
echo "Installed plugins by category:"
echo "  - Official Claude Code Plugins: ${#OFFICIAL_PLUGINS[@]}"
echo "  - Development Engineering: ${#DEV_PLUGINS[@]}"
echo "  - Code Quality & Testing: ${#QUALITY_PLUGINS[@]}"
echo "  - Automation & DevOps: ${#DEVOPS_PLUGINS[@]}"
echo "  - Workflow Orchestration: ${#WORKFLOW_PLUGINS[@]}"
echo "  - Documentation: ${#DOC_PLUGINS[@]}"
echo "  - Git Workflow: ${#GIT_PLUGINS[@]}"
echo "  - Security, Compliance & Legal: ${#SECURITY_PLUGINS[@]}"
echo "  - Project & Product Management: ${#PM_PLUGINS[@]}"
echo ""
TOTAL=$((${#OFFICIAL_PLUGINS[@]} + ${#DEV_PLUGINS[@]} + ${#QUALITY_PLUGINS[@]} + ${#DEVOPS_PLUGINS[@]} + ${#WORKFLOW_PLUGINS[@]} + ${#DOC_PLUGINS[@]} + ${#GIT_PLUGINS[@]} + ${#SECURITY_PLUGINS[@]} + ${#PM_PLUGINS[@]}))
echo "Total plugins: $TOTAL"
echo ""
echo "Run '/plugin' to manage installed plugins"
echo "Run '/plugin list' to see all installed plugins"
