# scripts/create.nix
{ pkgs, pog }:

pog.pog {
  name = "create";
  version = "2.0.0";
  description = "Create disk image or archive for key distribution (extracts from pass)";

  arguments = [
    {
      name = "format";
      description = "output format: disk (SquashFS) or archive (tar.gz)";
    }
    {
      name = "hostname";
      description = "hostname to include keys for";
    }
  ];

  flags = [
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
    squashfsTools
    gnutar
    gzip
    coreutils
    findutils
    tree
    pass
    gnupg
  ];

  script = helpers: ''
    FORMAT="$1"
    HOST="$2"

    export PASSWORD_STORE_DIR="./private"

    if ${helpers.var.empty "FORMAT"}; then
      die "Error: Format required (disk or archive)"
    fi

    if ${helpers.var.empty "HOST"}; then
      die "Error: Hostname required"
    fi

    # Function to extract keys from pass to temp directory
    extract_keys_to_temp() {
      local host="$1"
      local temp_dir="$2"
      local user_list="$3"

      # Extract SSH host keys from pass
      if pass show "hosts/$host/ssh_host_ed25519_key" &>/dev/null; then
        cyan "Extracting SSH host keys (requires Yubikey)..."
        mkdir -p "$temp_dir/etc/ssh"
        pass show "hosts/$host/ssh_host_ed25519_key" > "$temp_dir/etc/ssh/ssh_host_ed25519_key"
        chmod 600 "$temp_dir/etc/ssh/ssh_host_ed25519_key"
        # Copy public key from public/
        if [ -f "public/hosts/$host/ssh_host_ed25519_key.pub" ]; then
          cp "public/hosts/$host/ssh_host_ed25519_key.pub" "$temp_dir/etc/ssh/"
        fi
      fi

      # Extract deploy keys from pass
      if pass show "hosts/$host/deploy_key_ed25519" &>/dev/null; then
        cyan "Extracting deploy keys (requires Yubikey)..."
        mkdir -p "$temp_dir/root/.ssh"
        pass show "hosts/$host/deploy_key_ed25519" > "$temp_dir/root/.ssh/deploy_key_ed25519"
        chmod 600 "$temp_dir/root/.ssh/deploy_key_ed25519"
        # Copy public key from public/
        if [ -f "public/hosts/$host/deploy_key_ed25519.pub" ]; then
          cp "public/hosts/$host/deploy_key_ed25519.pub" "$temp_dir/root/.ssh/"
        fi
      fi

      # Extract user keys if specified
      if ${helpers.var.notEmpty "user_list"}; then
        if [ "$user_list" = "*" ]; then
          # Extract all users from pass
          if [ -d "public/home" ]; then
            cyan "Extracting all user keys (requires Yubikey)..."
            for user_pub_dir in public/home/*; do
              if [ -d "$user_pub_dir" ]; then
                user=$(basename "$user_pub_dir")
                if pass show "home/$user/id_ed25519" &>/dev/null; then
                  mkdir -p "$temp_dir/home/$user/.ssh"
                  pass show "home/$user/id_ed25519" > "$temp_dir/home/$user/.ssh/id_ed25519"
                  chmod 600 "$temp_dir/home/$user/.ssh/id_ed25519"
                  cp "$user_pub_dir"/*.pub "$temp_dir/home/$user/.ssh/" 2>/dev/null || true
                fi
              fi
            done
          fi
        else
          # Extract specific users (comma-separated)
          IFS=',' read -ra USERS <<< "$user_list"
          for user in "''${USERS[@]}"; do
            user=$(echo "$user" | xargs)  # trim whitespace
            if pass show "home/$user/id_ed25519" &>/dev/null; then
              cyan "Extracting keys for user: $user (requires Yubikey)"
              mkdir -p "$temp_dir/home/$user/.ssh"
              pass show "home/$user/id_ed25519" > "$temp_dir/home/$user/.ssh/id_ed25519"
              chmod 600 "$temp_dir/home/$user/.ssh/id_ed25519"
              cp "public/home/$user"/*.pub "$temp_dir/home/$user/.ssh/" 2>/dev/null || true
            else
              yellow "Warning: User key not found in pass: home/$user/id_ed25519 (skipping)"
            fi
          done
        fi
      else
        cyan "No users specified, host keys only"
      fi
    }

    # Check if host exists in pass
    if ! pass show "hosts/$HOST/ssh_host_ed25519_key" &>/dev/null; then
      die "Error: Host keys not found in pass: hosts/$HOST\nRun: genkey host $HOST"
    fi

    case "$FORMAT" in
      disk)
        OUTPUT="$output"
        if ${helpers.var.empty "OUTPUT"}; then
          OUTPUT="$HOST-keys.img"
        fi

        green "Creating SquashFS disk for host '$HOST': $OUTPUT"
        TEMP_DIR=$(mktemp -d)
        trap 'rm -rf $TEMP_DIR' EXIT

        extract_keys_to_temp "$HOST" "$TEMP_DIR" "$users"

        echo ""
        cyan "Contents:"
        tree -L 3 "$TEMP_DIR" 2>/dev/null || ls -la "$TEMP_DIR"

        echo ""
        cyan "Creating compressed SquashFS image..."
        mksquashfs "$TEMP_DIR" "$OUTPUT" -quiet -noappend -comp xz

        ACTUAL_SIZE=$(du -h "$OUTPUT" | cut -f1)

        echo ""
        green "✓ Disk created: $OUTPUT"
        echo "  Host: $HOST"
        echo "  Format: SquashFS (read-only, compressed)"
        echo "  Size: $ACTUAL_SIZE"
        echo "  Use: QEMU testing"
        ;;

      archive)
        OUTPUT="$output"
        if ${helpers.var.empty "OUTPUT"}; then
          OUTPUT="$HOST-keys.tar.gz"
        fi

        green "Creating Ventoy archive for host '$HOST': $OUTPUT"
        TEMP_DIR=$(mktemp -d)
        trap 'rm -rf $TEMP_DIR' EXIT

        extract_keys_to_temp "$HOST" "$TEMP_DIR" "$users"

        echo ""
        cyan "Creating tar.gz archive..."
        ORIGINAL_DIR="$(pwd)"
        cd "$TEMP_DIR" || die "Failed to change directory"
        tar czf "$ORIGINAL_DIR/$OUTPUT" ./* 2>/dev/null || true
        cd "$ORIGINAL_DIR" || die "Failed to return to original directory"

        echo ""
        green "✓ Archive created: $OUTPUT"
        echo "  Host: $HOST"
        echo "  Format: tar.gz"
        echo "  Use: Ventoy injection"
        echo ""
        cyan "Contents:"
        tar tzf "$OUTPUT"
        ;;

      *)
        die "Error: Unknown format '$FORMAT'. Valid formats: disk, archive"
        ;;
    esac
  '';
}
