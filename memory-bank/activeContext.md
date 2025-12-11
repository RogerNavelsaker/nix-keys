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

1. [2025-12-11] Migrated private keys to pass (GPG-encrypted)
2. [2025-12-11] Moved public keys to public/ directory
3. [2025-12-11] Updated all scripts to use pass for key operations
4. [2025-12-11] Removed push blocking (encryption makes remote safe)
5. [2025-12-11] Cleaned git history to remove plaintext keys
6. [2025-12-11] Pushed to GitHub (hellst0rm/nix-keys - private)
7. [2025-12-11] Updated AGENTS.md and README.md
8. [2025-12-11] Renamed repo from nixos-keys to nix-keys

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
