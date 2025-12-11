---
title: Project Brief - nixos-keys
type: note
permalink: nixos-keys-project-brief
tags:
  - project
  - keys
  - local-only
---

# Project Brief - nixos-keys

## Overview

Local-only SSH and deploy key management for NixOS ISO deployments.

**WARNING: This repository must NEVER be pushed to any remote.**

## Observations

- [scope] Generates and stores SSH host keys, deploy keys, and user keys
- [architecture] Per-host and per-user key directories
- [stack] SSH, age, gh CLI, QEMU utilities
- [security] Keys are LOCAL-ONLY, never pushed to remote

## Core Requirements

1. Generate SSH host keys for ISO installations
2. Generate deploy keys for private repo access
3. Generate user SSH keys for initial setup
4. Create QEMU disk images with keys
5. Create Ventoy archives for USB installation

## Key Structure

- `hosts/<hostname>/ssh/` - SSH host keys
- `hosts/<hostname>/deploy/` - Deploy keys
- `home/<username>/` - User SSH keys

## FORBIDDEN Operations

- git push - NEVER
- Remote operations via GitHub MCP - FORBIDDEN
- External sharing - FORBIDDEN

## Relations

- provides_keys_for [[nixos-config]] (ISO loads keys)
- provides_deploy_keys_for [[nixos-secrets]] (repo access)
