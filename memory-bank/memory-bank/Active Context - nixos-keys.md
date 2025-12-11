---
title: Active Context - nixos-keys
type: note
permalink: memory-bank/active-context-nixos-keys
tags:
- active
- context
---

# Active Context - nixos-keys

## Current Focus

AI/LLM tool-agnostic repository setup.

## Recent Events

1. [2025-12-10] Renamed CLAUDE.md to AGENTS.md for tool-agnostic naming
2. [2025-12-10] Added AI tool configs to .gitignore
3. [2025-12-10] Removed Claude-specific references from documentation
4. [2025-12-10] Removed Claude sandbox infrastructure
5. [2025-12-10] Cleaned up ACLs and file permissions
6. [2025-12-08] Created AGENTS.md project documentation
7. [2025-12-08] Initialized memory-bank directory structure
8. [2025-12-08] Registered project with Basic Memory

## Active Decisions

- Keys are LOCAL-ONLY, never pushed
- QEMU disk contains ALL keys for testing
- Ventoy archives are host-specific
- AI tool configs are user-specific, not committed to git

## Next Steps

- Continue normal development workflow

## REMINDER: FORBIDDEN OPERATIONS

- git push - NEVER
- Remote operations - FORBIDDEN

## Relations

- part_of [[nixos-keys]]
- relates_to [[nixos-config]]
