---
title: System Patterns - nix-keys
type: note
permalink: nix-keys-system-patterns
tags:
  - patterns
  - architecture
---

# System Patterns - nix-keys

## Architecture Overview

```
nix-keys/
├── private/           # GPG-encrypted pass store
│   ├── .gpg-id        # GPG key ID for encryption
│   ├── hosts/
│   │   └── <hostname>/
│   │       ├── ssh_host_ed25519_key.gpg
│   │       └── deploy_key_ed25519.gpg
│   └── home/
│       └── <username>/
│           └── id_ed25519.gpg
├── public/            # Plaintext public keys
│   ├── hosts/
│   │   └── <hostname>/*.pub
│   └── home/
│       └── <username>/*.pub
├── iso-keys.img       # QEMU disk output
└── iso-keys.tar.gz    # Ventoy archive output
```

## Observations

- [security] Private keys GPG-encrypted via pass (password-store)
- [security] Decryption requires Yubikey physical presence
- [pattern] SSH host keys identify server to clients
- [pattern] Deploy keys provide read-only repo access
- [pattern] User keys provide personal SSH authentication
- [pattern] QEMU disk has all keys, Ventoy archive is host-specific

## Key Patterns

### Key Generation Pattern (requires Yubikey)

```bash
# Generate SSH host key
genkey host <hostname>

# Generate deploy key
genkey deploy <hostname>

# Generate user key
genkey user <username>
```

### Deployment Media Pattern (requires Yubikey)

```bash
# QEMU: Host keys + optional users
create disk <hostname> [-u users]

# Ventoy: Host-specific archive
create archive <hostname> [-o output.tar.gz]
```

### GitHub Integration Pattern

```bash
# Upload deploy key to GitHub repo
deploy add <hostname> <owner/repo>
```

### Direct Pass Access Pattern

```bash
# Access private keys directly (requires Yubikey)
PASSWORD_STORE_DIR=./private pass show hosts/<hostname>/ssh_host_ed25519_key
PASSWORD_STORE_DIR=./private pass show home/<username>/id_ed25519
```

## Security Model

- **Encryption**: pass with GPG (Yubikey-backed key)
- **GPG Key ID**: 82D7B6F3AF8297688F10508CB692AA74EC31CD0B
- **Physical Security**: Yubikey touch required for decryption
- **Remote**: Safe to push (all sensitive data encrypted)

## Key Loading

- QEMU: ISO mounts disk labeled `nixos-keys`
- Ventoy: Archive injected into initramfs
- Keys extracted temporarily during media creation

## Relations

- defines [[Key Generation Pattern]]
- defines [[Deployment Media Pattern]]
- uses [[pass]]
- uses [[Yubikey GPG]]
