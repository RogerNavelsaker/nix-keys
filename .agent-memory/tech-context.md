---
title: Tech Context - nixos-keys
type: note
permalink: nixos-keys-tech-context
tags:
  - tech
  - stack
---

# Tech Context - nixos-keys

## Technology Stack

### Core Tools

| Tool | Purpose |
|------|---------|
| ssh-keygen | Key generation |
| tar/gzip | Ventoy archives |
| qemu-img | QEMU disk creation |
| gh | GitHub CLI for deploy keys |

### Development

- **devshell**: Development environment
- **git-hooks**: Pre-commit hooks
- **direnv**: Automatic shell activation

## Observations

- [constraint] LOCAL-ONLY repository
- [constraint] Never push to any remote
- [setup] Keys stored in hosts/ and users/ directories
- [setup] Devshell provides all necessary tools

## Commands Available

### Key Generation

| Command | Description |
|---------|-------------|
| `gen-ssh-host-key` | Generate SSH host key |
| `gen-deploy-key` | Generate deploy key |
| `gen-user-key` | Generate user SSH key |

### Media Creation

| Command | Description |
|---------|-------------|
| `create-qemu-disk` | Create QEMU disk image |
| `create-ventoy-archive` | Create Ventoy archive |

### Info

| Command | Description |
|---------|-------------|
| `list-keys` | List all generated keys |
| `show-host` | Show keys for host |
| `menu` | Show all commands |

## Relations

- uses [[SSH]]
- uses [[QEMU]]
- uses [[Ventoy]]
