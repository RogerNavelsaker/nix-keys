# scripts/create.nix
# Create key archives for deployment
# Two modes:
#   - archive: Decrypted keys (requires Yubikey at build time)
#   - injection: Encrypted pass store for Ventoy (GPG unlock at boot)
{ pkgs, pog }:

pog.pog {
  name = "create";
  version = "5.0.0";
  description = "Create key archives: decrypted (archive) or encrypted (injection)";

  arguments = [
    {
      name = "action";
      description = "action: archive, injection, info";
    }
  ];

  flags = [
    {
      name = "host";
      short = "H";
      description = "hostname for key lookup";
      argument = "HOST";
      default = "";
    }
    {
      name = "output";
      short = "o";
      description = "output filename";
      argument = "FILE";
      default = "";
    }
    {
      name = "users";
      short = "u";
      description = "users to include (comma-separated, or '*' for all)";
      argument = "USERS";
      default = "";
    }
  ];

  runtimeInputs = with pkgs; [
    gnutar
    gzip
    coreutils
    findutils
    pass
    gnupg
    tree
  ];

  script = helpers: ''
        ACTION="$1"

        # Action: archive (decrypted keys - requires Yubikey)
        do_archive() {
          HOST="$host"
          if ${helpers.var.empty "HOST"}; then
            die "Error: --host required for archive\nUsage: create archive -H <hostname> [-u users] [-o output.tar.gz]"
          fi

          export PASSWORD_STORE_DIR="./private"

          # Check if host exists in pass
          if ! pass show "hosts/$HOST/ssh_host_ed25519_key" &>/dev/null; then
            die "Error: Host keys not found in pass: hosts/$HOST\nRun: genkey host $HOST"
          fi

          OUTPUT="$output"
          if ${helpers.var.empty "OUTPUT"}; then
            OUTPUT="$HOST-keys.tar.gz"
          fi

          green "Creating decrypted key archive for host '$HOST': $OUTPUT"
          yellow "Note: This requires Yubikey and decrypts keys at build time"
          echo ""

          TEMP_DIR=$(mktemp -d)
          trap 'rm -rf $TEMP_DIR' EXIT

          # Extract SSH host keys from pass
          cyan "Extracting SSH host keys (requires Yubikey)..."
          mkdir -p "$TEMP_DIR/etc/ssh"
          pass show "hosts/$HOST/ssh_host_ed25519_key" > "$TEMP_DIR/etc/ssh/ssh_host_ed25519_key"
          chmod 600 "$TEMP_DIR/etc/ssh/ssh_host_ed25519_key"
          # Copy public key
          if [ -f "public/hosts/$HOST/ssh_host_ed25519_key.pub" ]; then
            cp "public/hosts/$HOST/ssh_host_ed25519_key.pub" "$TEMP_DIR/etc/ssh/"
          fi

          # Extract deploy key if exists
          if pass show "hosts/$HOST/deploy_key_ed25519" &>/dev/null; then
            cyan "Extracting deploy key (requires Yubikey)..."
            mkdir -p "$TEMP_DIR/root/.ssh"
            pass show "hosts/$HOST/deploy_key_ed25519" > "$TEMP_DIR/root/.ssh/deploy_key_ed25519"
            chmod 600 "$TEMP_DIR/root/.ssh/deploy_key_ed25519"
            # Copy public key
            if [ -f "public/hosts/$HOST/deploy_key_ed25519.pub" ]; then
              cp "public/hosts/$HOST/deploy_key_ed25519.pub" "$TEMP_DIR/root/.ssh/"
            fi
            # Create SSH config for GitHub
            cat > "$TEMP_DIR/root/.ssh/config" << 'SSH_EOF'
    Host github.com
      IdentityFile /root/.ssh/deploy_key_ed25519
      IdentitiesOnly yes
      StrictHostKeyChecking accept-new
    SSH_EOF
            chmod 600 "$TEMP_DIR/root/.ssh/config"
          fi

          # Extract user keys if specified
          if ${helpers.var.notEmpty "users"}; then
            if [ "$users" = "*" ]; then
              if [ -d "public/users" ]; then
                cyan "Extracting all user keys (requires Yubikey)..."
                for user_pub_dir in public/users/*; do
                  if [ -d "$user_pub_dir" ]; then
                    user=$(basename "$user_pub_dir")
                    if pass show "users/$user/id_ed25519" &>/dev/null; then
                      mkdir -p "$TEMP_DIR/home/$user/.ssh"
                      pass show "users/$user/id_ed25519" > "$TEMP_DIR/home/$user/.ssh/id_ed25519"
                      chmod 600 "$TEMP_DIR/home/$user/.ssh/id_ed25519"
                      cp "$user_pub_dir"/*.pub "$TEMP_DIR/home/$user/.ssh/" 2>/dev/null || true
                    fi
                  fi
                done
              fi
            else
              IFS=',' read -ra USERS <<< "$users"
              for user in "''${USERS[@]}"; do
                user=$(echo "$user" | xargs)
                if pass show "users/$user/id_ed25519" &>/dev/null; then
                  cyan "Extracting keys for user: $user (requires Yubikey)"
                  mkdir -p "$TEMP_DIR/home/$user/.ssh"
                  pass show "users/$user/id_ed25519" > "$TEMP_DIR/home/$user/.ssh/id_ed25519"
                  chmod 600 "$TEMP_DIR/home/$user/.ssh/id_ed25519"
                  cp "public/users/$user"/*.pub "$TEMP_DIR/home/$user/.ssh/" 2>/dev/null || true
                else
                  yellow "Warning: User key not found: users/$user/id_ed25519 (skipping)"
                fi
              done
            fi
          fi

          echo ""
          cyan "Creating tar.gz archive..."
          ORIGINAL_DIR="$(pwd)"
          cd "$TEMP_DIR" || die "Failed to change directory"
          tar czf "$ORIGINAL_DIR/$OUTPUT" ./* 2>/dev/null || true
          cd "$ORIGINAL_DIR" || die "Failed to return to original directory"

          echo ""
          green "✓ Archive created: $OUTPUT"
          echo "  Host: $HOST"
          echo "  Format: tar.gz (decrypted keys)"
          echo ""
          cyan "Contents:"
          tar tzf "$OUTPUT"
        }

        # Action: injection (encrypted pass store for Ventoy - NO Yubikey needed)
        do_injection() {
          HOST="$host"
          if ${helpers.var.empty "HOST"}; then
            die "Error: --host required for injection\nUsage: create injection -H <hostname> [-o output.tar.gz]"
          fi

          # Validate directories exist
          if [ ! -d "./private" ]; then
            die "Error: private/ directory not found"
          fi
          if [ ! -d "./public" ]; then
            die "Error: public/ directory not found"
          fi

          # Check host exists
          if [ ! -d "./private/hosts/$HOST" ]; then
            die "Error: Host not found: private/hosts/$HOST\nRun: genkey host $HOST"
          fi

          OUTPUT="$output"
          if ${helpers.var.empty "OUTPUT"}; then
            OUTPUT="$HOST-injection.tar.gz"
          fi

          green "Creating Ventoy injection archive for host '$HOST': $OUTPUT"
          cyan "Mode: Encrypted pass store (GPG/Yubikey unlock at boot)"
          echo ""

          TEMP_DIR=$(mktemp -d)
          trap 'rm -rf $TEMP_DIR' EXIT

          # Copy encrypted pass store structure
          cyan "Copying encrypted pass store (private/)..."
          mkdir -p "$TEMP_DIR/private"

          # Copy .gpg-id
          if [ -f "./private/.gpg-id" ]; then
            cp "./private/.gpg-id" "$TEMP_DIR/private/"
          fi

          # Copy host keys (encrypted .gpg files)
          mkdir -p "$TEMP_DIR/private/hosts/$HOST"
          cp -r "./private/hosts/$HOST"/* "$TEMP_DIR/private/hosts/$HOST/" 2>/dev/null || true

          # Copy common host files if exist
          if [ -d "./private/hosts/common" ]; then
            mkdir -p "$TEMP_DIR/private/hosts/common"
            cp -r "./private/hosts/common"/* "$TEMP_DIR/private/hosts/common/" 2>/dev/null || true
          fi

          # Copy user keys if specified
          if ${helpers.var.notEmpty "users"}; then
            if [ "$users" = "*" ]; then
              if [ -d "./private/users" ]; then
                cyan "Including all user keys..."
                cp -r "./private/users" "$TEMP_DIR/private/"
              fi
            else
              IFS=',' read -ra USERS <<< "$users"
              for user in "''${USERS[@]}"; do
                user=$(echo "$user" | xargs)
                if [ -d "./private/users/$user" ]; then
                  cyan "Including user: $user"
                  mkdir -p "$TEMP_DIR/private/users/$user"
                  cp -r "./private/users/$user"/* "$TEMP_DIR/private/users/$user/"
                else
                  yellow "Warning: User not found: private/users/$user (skipping)"
                fi
              done
            fi
          fi

          # Copy common user files if exist
          if [ -d "./private/users/common" ]; then
            mkdir -p "$TEMP_DIR/private/users/common"
            cp -r "./private/users/common"/* "$TEMP_DIR/private/users/common/" 2>/dev/null || true
          fi

          # Copy public keys
          cyan "Copying public keys (public/)..."
          mkdir -p "$TEMP_DIR/public"

          # Copy host public keys
          if [ -d "./public/hosts/$HOST" ]; then
            mkdir -p "$TEMP_DIR/public/hosts/$HOST"
            cp -r "./public/hosts/$HOST"/* "$TEMP_DIR/public/hosts/$HOST/" 2>/dev/null || true
          fi

          # Copy common host public keys
          if [ -d "./public/hosts/common" ]; then
            mkdir -p "$TEMP_DIR/public/hosts/common"
            cp -r "./public/hosts/common"/* "$TEMP_DIR/public/hosts/common/" 2>/dev/null || true
          fi

          # Copy user public keys if users specified
          if ${helpers.var.notEmpty "users"}; then
            if [ "$users" = "*" ]; then
              if [ -d "./public/users" ]; then
                cp -r "./public/users" "$TEMP_DIR/public/"
              fi
            else
              IFS=',' read -ra USERS <<< "$users"
              for user in "''${USERS[@]}"; do
                user=$(echo "$user" | xargs)
                if [ -d "./public/users/$user" ]; then
                  mkdir -p "$TEMP_DIR/public/users/$user"
                  cp -r "./public/users/$user"/* "$TEMP_DIR/public/users/$user/" 2>/dev/null || true
                fi
              done
            fi
          fi

          # Copy common user public keys
          if [ -d "./public/users/common" ]; then
            mkdir -p "$TEMP_DIR/public/users/common"
            cp -r "./public/users/common"/* "$TEMP_DIR/public/users/common/" 2>/dev/null || true
          fi

          # Export GPG public key for boot-time import
          cyan "Exporting GPG public key..."
          GPG_ID=$(cat "./private/.gpg-id" 2>/dev/null || echo "")
          if [ -n "$GPG_ID" ]; then
            gpg --export --armor "$GPG_ID" > "$TEMP_DIR/private/.gpg-pubkey.asc" 2>/dev/null || \
              yellow "Warning: Could not export GPG public key"
          fi

          echo ""
          cyan "Archive structure:"
          tree "$TEMP_DIR" 2>/dev/null || find "$TEMP_DIR" -type f

          echo ""
          cyan "Creating tar.gz archive..."
          ORIGINAL_DIR="$(pwd)"
          cd "$TEMP_DIR" || die "Failed to change directory"
          tar czf "$ORIGINAL_DIR/$OUTPUT" ./* 2>/dev/null || tar czf "$ORIGINAL_DIR/$OUTPUT" *
          cd "$ORIGINAL_DIR" || die "Failed to return to original directory"

          ACTUAL_SIZE=$(du -h "$OUTPUT" | cut -f1)

          echo ""
          green "✓ Injection archive created: $OUTPUT"
          echo "  Host: $HOST"
          echo "  Size: $ACTUAL_SIZE"
          echo "  Format: tar.gz (encrypted, GPG unlock at boot)"
          echo ""
          yellow "Usage:"
          echo "  This archive is for Ventoy disk injection."
          echo "  Use: nix-repos ventoy create -H $HOST --injection $OUTPUT"
        }

        # Action: info
        do_info() {
          echo "nix-keys repository structure:"
          echo ""
          echo "Available hosts:"
          if [ -d "./private/hosts" ]; then
            for host_dir in ./private/hosts/*; do
              if [ -d "$host_dir" ]; then
                host_name=$(basename "$host_dir")
                if [ "$host_name" != "common" ]; then
                  echo "  - $host_name"
                fi
              fi
            done
          fi
          echo ""
          echo "Available users:"
          if [ -d "./private/users" ]; then
            for user_dir in ./private/users/*; do
              if [ -d "$user_dir" ]; then
                user_name=$(basename "$user_dir")
                if [ "$user_name" != "common" ]; then
                  echo "  - $user_name"
                fi
              fi
            done
          fi
        }

        # Main dispatch
        case "$ACTION" in
          archive)
            do_archive
            ;;
          injection)
            do_injection
            ;;
          info)
            do_info
            ;;
          "")
            die "Error: Action required\n\nActions:\n  archive    - Create decrypted key archive (requires Yubikey)\n  injection  - Create encrypted pass store for Ventoy (no Yubikey needed)\n  info       - Show available hosts and users\n\nFlags:\n  -H, --host HOST    - Hostname for key lookup (required)\n  -o, --output FILE  - Output filename\n  -u, --users USERS  - Users to include (comma-separated or '*')\n\nExamples:\n  create archive -H iso              # Decrypted keys (requires Yubikey)\n  create archive -H iso -u rona      # Include user keys\n  create injection -H iso            # Encrypted for Ventoy boot\n  create injection -H iso -u '*'     # Include all users\n  create info                        # List hosts/users"
            ;;
          *)
            die "Unknown action: $ACTION\nValid actions: archive, injection, info"
            ;;
        esac
  '';
}
