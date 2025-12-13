# nix-keys

SSH key management with pass + Yubikey GPG encryption for NixOS deployments.

## Security Model

Private keys are GPG-encrypted via `pass` (password-store). Decryption requires Yubikey physical presence. The repo can be safely pushed to GitHub (private) since all sensitive data is encrypted.

## Repository Structure

```
nix-keys/
├── flake.nix          # Flake with devshell
├── flake.lock         # Pinned dependencies
├── private/           # GPG-encrypted pass store
│   ├── .gpg-id        # GPG key ID for encryption
│   ├── hosts/         # Encrypted host keys
│   │   └── <hostname>/
│   │       ├── ssh_host_ed25519_key.gpg
│   │       └── deploy_key_ed25519.gpg
│   └── users/         # Encrypted user keys
│       └── <username>/
│           └── id_ed25519.gpg
├── public/            # Plaintext public keys
│   ├── hosts/
│   │   └── <hostname>/*.pub
│   └── users/
│       └── <username>/*.pub
├── scripts/           # Helper scripts
├── githooks.nix       # Git hooks
└── shell.nix          # Development shell
```

## Key Types

| Type | Private Location | Public Location | Purpose |
|------|------------------|-----------------|---------|
| SSH Host Keys | `private/hosts/<host>/ssh_host_ed25519_key.gpg` | `public/hosts/<host>/*.pub` | Server identity |
| Deploy Keys | `private/hosts/<host>/deploy_key_ed25519.gpg` | `public/hosts/<host>/*.pub` | Git repo access |
| User Keys | `private/users/<user>/id_ed25519.gpg` | `public/users/<user>/*.pub` | Personal SSH auth |

## Commands

### Key Generation (requires Yubikey)

| Command | Usage | Description |
|---------|-------|-------------|
| `genkey` | `genkey host <hostname>` | Generate SSH host key |
| `genkey` | `genkey deploy <hostname>` | Generate deploy key |
| `genkey` | `genkey user <username>` | Generate user SSH key |

### Disk/Archive Creation (requires Yubikey)

| Command | Usage | Description |
|---------|-------|-------------|
| `create` | `create disk <hostname> [-u users]` | Create SquashFS disk for QEMU |
| `create` | `create archive <hostname> [-u users]` | Create tar.gz for Ventoy |

### GitHub Integration

| Command | Usage | Description |
|---------|-------|-------------|
| `deploy` | `deploy add <host> <owner/repo>` | Upload deploy key to GitHub |
| `deploy` | `deploy list <owner/repo>` | List deploy keys on repo |

### Info

| Command | Description |
|---------|-------------|
| `list` | List all generated keys (public only) |
| `show <type> <name>` | Show keys for host or user |
| `menu` | Show all commands |

## Workflows

### QEMU Testing

```bash
genkey host iso
genkey deploy iso
genkey user rona
create disk iso -u rona
# Use with: run-iso-with-keys in nix-config
```

### Ventoy USB

```bash
genkey host iso
genkey deploy iso
create archive iso iso-keys.tar.gz
# Copy ISO and archive to Ventoy USB
```

## Access Commands

```bash
# List public keys (no Yubikey needed)
list
show host iso
show user rona

# Access private keys (requires Yubikey)
PASSWORD_STORE_DIR=./private pass show hosts/iso/ssh_host_ed25519_key
PASSWORD_STORE_DIR=./private pass show users/rona/id_ed25519
```

## GPG Key

GPG Key ID: `82D7B6F3AF8297688F10508CB692AA74EC31CD0B`

The private GPG key resides on Yubikey. Physical touch required for decryption.

## Related Repositories

- `nix-config`: Main system configuration (loads keys from disk/archive)
- `nix-secrets`: SOPS-encrypted secrets (deploy keys provide access)

## Recommended MCP Servers

This is a Nix repository. For AI assistants with MCP support:

**Project-specific** (configure in `.mcp.json`):
- `nixos` - NixOS/Home Manager/nix-darwin option lookups via `uvx mcp-nixos`

**Global** (user's global config):
- `basic-memory` - Knowledge management
- `modern-cli` - Modern CLI tools, fetch, github
- `sequentialthinking` - Complex reasoning

`.mcp.json` is gitignored - each user configures their own.
