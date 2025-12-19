
# Summary

The repo is essentially a **power-user framework** built from 6 months of production use. It extends Claude Code's capabilities, not Claude's core intelligence—it's about **workflow optimization** and **context management**.
# Claude Skills vs. claude-code-infrastructure-showcase

A comparison between Claude's native capabilities and what [this repository](https://github.com/diet103/claude-code-infrastructure-showcase) adds for **Claude Code** (the CLI tool).

---

## Comparison Table

| Aspect | Claude's Native Capabilities | This Repo's Add-ons |
|--------|------------------------------|---------------------|
| **Context** | Works with whatever context is in the current conversation | Adds **persistent "skills"** (markdown docs) that survive context resets |
| **Activation** | You have to tell Claude what you want | **Auto-activating hooks** that detect your intent and suggest relevant skills automatically |
| **Memory** | Limited to current session (unless memory feature enabled) | **Dev docs pattern** preserves project knowledge across sessions |
| **Specialization** | General-purpose assistant | **10 specialized agents** (refactoring, code review, debugging, etc.) |
| **Project Standards** | Follows your instructions | **Guardrails baked in** - enforces your coding patterns (Express/React/TypeScript standards) |

---

## Key Innovations in the Repo

### 1. The "Skills Don't Activate" Problem Solved

- **Native Claude Code:** Skills are passive—you must remember to invoke them
- **This repo:** `UserPromptSubmit` hook + `skill-rules.json` = skills suggest themselves based on context

### 2. 500-Line Modular Pattern

- Keeps individual skill files under context limits
- Progressive disclosure: loads only what's needed

### 3. Hooks System (the core innovation)

| Hook | Purpose |
|------|---------|
| `skill-activation-prompt` | Analyzes prompts, suggests skills |
| `post-tool-use-tracker` | Tracks file changes |
| Stop hooks | Validation (TSC checks, build verification) |
