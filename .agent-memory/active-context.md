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


1. [2025-12-12] Replaced SquashFS disk with Ventoy image creation
2. [2025-12-12] Consolidated qemu.nix into create.nix
3. [2025-12-12] Added ventoy, libguestfs, util-linux dependencies
4. [2025-12-12] Renamed memory-bank/ to .agent-memory/ with kebab-case files
5. [2025-12-12] Re-registered project with Basic Memory at new path
6. [2025-12-11] Git history fully sanitized - squashed to single commit
7. [2025-12-11] Migrated private keys to pass (GPG-encrypted)
8. [2025-12-11] Moved public keys to public/ directory
9. [2025-12-11] Pushed to GitHub (hellst0rm/nix-keys - private)


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
