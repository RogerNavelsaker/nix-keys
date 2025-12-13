# nix-keys

SSH key management with pass + Yubikey GPG encryption for NixOS ISO deployments.

## Overview

Private keys are GPG-encrypted via `pass` (password-store). Decryption requires Yubikey physical presence. This allows the repo to be safely backed up to GitHub (private) since all sensitive data is encrypted.

```
nix-keys/
├── private/           # GPG-encrypted pass store
│   ├── hosts/         # Host keys (encrypted)
│   └── users/         # User keys (encrypted)
└── public/            # Public keys (plaintext)
    ├── hosts/
    └── users/
```

## Quick Start

```bash
# Enter development environment
cd nix-keys
nix develop

# Generate keys for a host (requires Yubikey)
genkey host iso
genkey deploy iso

# Generate user keys
genkey user rona

# Create QEMU disk (requires Yubikey to extract)
create disk iso -u rona

# Create Ventoy archive
create archive iso

# View all commands
menu
```

## Commands

### Generate Keys (requires Yubikey)

| Command | Usage | Description |
|---------|-------|-------------|
| `genkey` | `genkey host <hostname>` | Generate SSH host key (ed25519) |
| `genkey` | `genkey deploy <hostname>` | Generate deploy key (ed25519) |
| `genkey` | `genkey user <username>` | Generate user SSH key (ed25519) |

**Examples:**
```bash
# Generate SSH host keys for 'iso' host
genkey host iso

# Generate deploy key for pulling private repos
genkey deploy iso

# Generate SSH key for user 'rona'
genkey user rona
```

### GitHub Integration

| Command | Usage | Description |
|---------|-------|-------------|
| `deploy` | `deploy add <hostname> <owner/repo>` | Upload deploy key to GitHub |
| `deploy` | `deploy remove <owner/repo> <key-id>` | Remove deploy key |
| `deploy` | `deploy list <owner/repo>` | List deploy keys |

**Example:**
```bash
# Upload deploy key to GitHub repo
genkey deploy iso
deploy add iso hellst0rm/nix-secrets
```

### Create Disks/Archives (requires Yubikey)

| Command | Usage | Description |
|---------|-------|-------------|
| `create` | `create disk <hostname> [-u users] [-o file]` | Create SquashFS disk |
| `create` | `create archive <hostname> [-u users] [-o file]` | Create tar.gz archive |

**Examples:**
```bash
# Create QEMU disk for host 'iso' with user 'rona'
create disk iso -u rona -o iso-keys.img

# Create Ventoy archive
create archive iso -o iso-keys.tar.gz
```

### Info Commands

| Command | Usage | Description |
|---------|-------|-------------|
| `list` | `list` | List all generated keys (public) |
| `show` | `show host <hostname>` | Show keys for host |
| `show` | `show user <username>` | Show keys for user |

## Workflows

### QEMU Workflow

```bash
# 1. Generate keys (Yubikey touch required)
nix develop
genkey host iso
genkey deploy iso
genkey user rona

# 2. Create QEMU disk (Yubikey touch required)
create disk iso -u rona

# 3. Build and run ISO (in nix-config repo)
cd ../nix-config
build-iso
run-iso-with-keys ../nix-keys/iso-keys.img

# 4. SSH into ISO
ssh -p 2222 root@localhost
```

### Ventoy Workflow

```bash
# 1. Generate keys (Yubikey touch required)
nix develop
genkey host iso
genkey deploy iso

# 2. Create Ventoy archive (Yubikey touch required)
create archive iso -o iso-keys.tar.gz

# 3. Build ISO (in nix-config repo)
cd ../nix-config
just build-iso

# 4. Copy to Ventoy USB
cp result/iso/*.iso /mnt/ventoy/
cp ../nix-keys/iso-keys.tar.gz /mnt/ventoy/

# 5. Configure Ventoy injection
cat > /mnt/ventoy/ventoy/ventoy.json << 'EOF'
{
  "injection": [
    {
      "image": "/iso.iso",
      "archive": "/iso-keys.tar.gz"
    }
  ]
}
EOF
```

## Directory Structure

### Private (GPG-encrypted)

```
private/
├── .gpg-id                          # GPG key ID
├── hosts/<hostname>/
│   ├── ssh_host_ed25519_key.gpg     # Encrypted host key
│   └── deploy_key_ed25519.gpg       # Encrypted deploy key
└── users/<username>/
    └── id_ed25519.gpg               # Encrypted user key
```

### Public (plaintext)

```
public/
├── hosts/<hostname>/
│   ├── ssh_host_ed25519_key.pub     # Public host key
│   └── deploy_key_ed25519.pub       # Public deploy key
└── users/<username>/
    └── id_ed25519.pub               # Public user key
```

## Accessing Private Keys

Private keys require Yubikey for decryption:

```bash
# In the nix-keys directory
PASSWORD_STORE_DIR=./private pass show hosts/iso/ssh_host_ed25519_key
PASSWORD_STORE_DIR=./private pass show hosts/iso/deploy_key_ed25519
PASSWORD_STORE_DIR=./private pass show users/rona/id_ed25519
```

Or with the shell environment (PASSWORD_STORE_DIR is set automatically):

```bash
nix develop
pass show hosts/iso/ssh_host_ed25519_key
```

## Key Types

**SSH Host Keys** (`hosts/<hostname>/ssh_host_ed25519_key`)
- Identify the server to clients
- Prevent MITM warnings on reconnect
- Generated with `genkey host`

**Deploy Keys** (`hosts/<hostname>/deploy_key_ed25519`)
- Read-only access to private git repos
- Used for cloning during installation
- Generated with `genkey deploy`
- Upload to GitHub with `deploy add`

**User Keys** (`users/<username>/id_ed25519`)
- Personal SSH authentication
- Generated with `genkey user`

## GPG Key Info

GPG Key ID: `82D7B6F3AF8297688F10508CB692AA74EC31CD0B`

The private GPG key resides on Yubikey. Physical touch is required for all decryption operations (key generation, disk/archive creation).

## Integration with nix-config

The ISO configuration automatically detects and loads keys:
- Mounts disk labeled `nixos-keys`
- Copies keys to correct locations
- Sets proper permissions
- No manual intervention needed

See: `../nix-config/hosts/iso/README.md` for ISO configuration details.
