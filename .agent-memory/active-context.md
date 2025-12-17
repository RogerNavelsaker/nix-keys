---
title: Active Context - nix-keys
type: note
permalink: nix-keys-active-context
tags:
  - active
  - context
---

# Active Context - nix-keys

## Current Focus

Flexible auth: choose between FlakeHub token or deploy key for private flake access.

## Recent Events

1. [2025-12-17] Fixed pre-commit src path (self → ./.}) for Nix reinstall compatibility
2. [2025-12-16] Added deploy key type to genkey command
3. [2025-12-16] Added --auth flag to create: flakehub, deploy, both, or auto-detect
4. [2025-12-16] Deploy key extraction to /root/.ssh/ with SSH config for GitHub
5. [2025-12-16] Fixed deploy.nix to use public/ directory path
6. [2025-12-15] Released v0.1.1 - fixed genkey PASSWORD_STORE_DIR bug
7. [2025-12-15] Fixed genkey script: use $PWD/private instead of ./private
8. [2025-12-15] Added FlakeHub token for iso host
9. [2025-12-15] Added fh CLI to devshell
10. [2025-12-12] Replaced SquashFS disk with Ventoy image creation


## Active Decisions

- Private keys stored in pass (./private/) - GPG encrypted
- Public keys stored in plaintext (./public/)
- Yubikey required for all decryption operations
- Repository can be safely pushed to GitHub (private)
- GPG Key ID: 82D7B6F3AF8297688F10508CB692AA74EC31CD0B
- Auth method selectable: FlakeHub token OR deploy key OR both

## Security Model

- Private keys: GPG-encrypted via pass, requires Yubikey touch
- Git history: Cleaned of all plaintext key traces
- Remote: Safe to push (encrypted data only)

## Next Steps

- Test key generation workflow with Yubikey
- Test disk/archive creation workflow
- Verify ISO key injection still works

## Relations

- part_of [[nix-repos]]
- uses [[pass]]
- uses [[Yubikey GPG]]
