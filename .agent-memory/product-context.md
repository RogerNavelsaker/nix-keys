---
title: Product Context - nixos-keys
type: note
permalink: nixos-keys-product-context
tags:
  - context
  - keys
---

# Product Context - nixos-keys

## Why This Project Exists

- [problem] Fresh NixOS installations need SSH keys but can't generate securely in live environment
- [problem] Deploy keys needed for private repo access during installation
- [problem] Keys must be injected into ISO at boot time

## Observations

- [solution] Pre-generate all required keys before installation
- [solution] Package keys into QEMU disk or Ventoy archive
- [solution] ISO loads keys from external media at boot
- [solution] Keys never stored in any remote repository

## User Experience Goals

- [ux] Single command to generate any key type
- [ux] Single command to create deployment media
- [ux] Easy GitHub deploy key upload
- [ux] Clear command menu via `menu` command

## How It Works

1. Generate keys with `gen-*` commands
2. Upload deploy keys to GitHub if needed
3. Create QEMU disk or Ventoy archive
4. Boot ISO with keys mounted/injected
5. ISO automatically loads keys to correct locations

## Relations

- implements [[Key Injection Pattern]]
- follows [[Security Best Practices]]
