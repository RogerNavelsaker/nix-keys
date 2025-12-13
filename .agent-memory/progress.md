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

Repository configured with key generation and deployment tools.

## What Works

- [x] SSH host key generation
- [x] Deploy key generation
- [x] User key generation
- [x] QEMU disk creation
- [x] Ventoy archive creation
- [x] GitHub deploy key upload
- [x] Devshell with all commands

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
