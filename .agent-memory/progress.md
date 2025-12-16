---
title: Progress - nixos-keys
type: note
permalink: nixos-keys-progress
tags:
  - progress
  - status
---

# Progress - nixos-keys

## Current Status

v0.2.0 - Flexible auth: FlakeHub token or deploy key for private flake access.

## What Works

- [x] SSH host key generation
- [x] Deploy key generation (`genkey deploy`)
- [x] User key generation
- [x] FlakeHub token storage
- [x] QEMU disk creation
- [x] Ventoy archive creation
- [x] GitHub deploy key upload
- [x] Devshell with all commands (incl. fh CLI)
- [x] Auth method selection (`--auth` flag: flakehub, deploy, both, auto)

## What's Left

- [ ] Generate keys for additional hosts as needed
- [ ] Document key rotation procedures

## Known Issues

None currently.

## Blockers

None currently.

## REMINDER


- This repo: generates keys, archives, Ventoy disks (takes ISO as input)
- nix-config: builds ISOs, runs QEMU testing with disk from this repo


## Relations

- tracks [[nixos-keys]]
