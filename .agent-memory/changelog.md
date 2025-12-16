---
title: Changelog - nixos-keys
type: note
permalink: nixos-keys-changelog
tags:
  - changelog
  - history
---

# Changelog - nixos-keys

## [0.2.0] - 2025-12-16

### Added
- `genkey deploy <hostname>` - generate deploy keys for SSH-based private repo access
- `--auth`/`-a` flag to `create` command: choose `flakehub`, `deploy`, `both`, or auto-detect
- Deploy key extraction to `/root/.ssh/deploy_key` with SSH config for GitHub
- Auto-detection of available auth methods when `--auth` not specified

### Fixed
- `deploy.nix` paths updated to use `public/hosts/` directory

## [0.1.1] - 2025-12-15

### Fixed
- genkey: use absolute path ($PWD/private) for PASSWORD_STORE_DIR to fix git pathspec error when pass auto-commits

### Added
- FlakeHub token storage via genkey flakehub command
- fh CLI to devshell

### Changed
- Reverted devshell input to github (FlakeHub unavailable)

## [Unreleased]

### Added
- CLAUDE.md project documentation
- memory-bank directory with project context files
- Basic Memory project registration

### Removed
- .clineignore file (migrating to Claude Code)

## [Initial] - 2025-12

### Added
- SSH host key generation
- Deploy key generation
- User key generation
- QEMU disk creation for testing
- Ventoy archive creation for USB
- GitHub deploy key upload integration
- Devshell with all management commands
