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

Repository migrated to pass + Yubikey GPG encryption model.

## Recent Events

1. [2025-12-12] Renamed memory-bank/ to .agent-memory/ with kebab-case files
2. [2025-12-12] Re-registered project with Basic Memory at new path
3. [2025-12-11] Git history fully sanitized - squashed to single commit
4. [2025-12-11] Removed nested memory-bank/memory-bank/ directory
5. [2025-12-11] Force-pushed clean history to GitHub
6. [2025-12-11] Migrated private keys to pass (GPG-encrypted)
7. [2025-12-11] Moved public keys to public/ directory
8. [2025-12-11] Pushed to GitHub (hellst0rm/nix-keys - private)

## Active Decisions

- Private keys stored in pass (./private/) - GPG encrypted
- Public keys stored in plaintext (./public/)
- Yubikey required for all decryption operations
- Repository can be safely pushed to GitHub (private)
- GPG Key ID: 82D7B6F3AF8297688F10508CB692AA74EC31CD0B

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
