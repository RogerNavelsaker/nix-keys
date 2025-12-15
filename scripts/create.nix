# scripts/create.nix
{ pkgs, pog }:

pog.pog {
  name = "create";
  version = "3.0.0";
  description = "Create archive or Ventoy disk for key distribution";

  arguments = [
    {
      name = "format";
      description = "output format: archive (tar.gz) or disk (Ventoy image)";
    }
    {
      name = "hostname";
      description = "hostname to include keys for";
    }
    {
      name = "iso-path";
      description = "ISO file path (required for disk format)";
      optional = true;
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
    ventoy
    libguestfs-with-appliance
    util-linux
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
        ISO_PATH="$3"

        export PASSWORD_STORE_DIR="./private"

        if ${helpers.var.empty "FORMAT"}; then
          die "Error: Format required (archive or disk)"
        fi

        if ${helpers.var.empty "HOST"}; then
          die "Error: Hostname required"
        fi

        # Cleanup function for disk creation
        cleanup_on_exit() {
          if [ -n "$MOUNT_POINT" ] && mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
            fusermount -u "$MOUNT_POINT" 2>/dev/null || true
          fi
          [ -n "$MOUNT_POINT" ] && rmdir "$MOUNT_POINT" 2>/dev/null || true
          [ -n "$LOOP_DEV" ] && sudo losetup -d "$LOOP_DEV" 2>/dev/null || true
          [ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
          [ -n "$KEYS_ARCHIVE" ] && [ -f "$KEYS_ARCHIVE" ] && rm -f "$KEYS_ARCHIVE"
        }

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

          # Extract FlakeHub token from pass
          if pass show "hosts/$host/flakehub_token" &>/dev/null; then
            cyan "Extracting FlakeHub token (requires Yubikey)..."
            mkdir -p "$temp_dir/nix/var/determinate"
            pass show "hosts/$host/flakehub_token" > "$temp_dir/nix/var/determinate/flakehub-token"
            chmod 600 "$temp_dir/nix/var/determinate/flakehub-token"
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
            # Validate ISO path
            if ${helpers.var.empty "ISO_PATH"}; then
              die "Error: ISO path required for disk format\nUsage: create disk <hostname> <iso-path>"
            fi

            if [ ! -f "$ISO_PATH" ]; then
              die "Error: ISO file not found: $ISO_PATH"
            fi

            OUTPUT="$output"
            if ${helpers.var.empty "OUTPUT"}; then
              OUTPUT="$HOST-ventoy.img"
            fi

            trap cleanup_on_exit EXIT

            ISO_NAME=$(basename "$ISO_PATH")
            green "Creating Ventoy disk for host '$HOST': $OUTPUT"
            echo "  ISO: $ISO_NAME"

            # Generate keys archive
            cyan "Generating key injection archive (requires Yubikey)..."
            KEYS_ARCHIVE=$(mktemp --suffix=.tar.gz)

            # Build user flag if specified
            USER_FLAG=""
            if ${helpers.var.notEmpty "users"}; then
              USER_FLAG="-u $users"
            fi

            # Create archive (recursive call)
            # shellcheck disable=SC2086
            create archive "$HOST" $USER_FLAG -o "$KEYS_ARCHIVE" || die "Failed to create key archive"

            # Calculate disk size
            ISO_SIZE=$(stat -c%s "$ISO_PATH")
            KEYS_SIZE=$(stat -c%s "$KEYS_ARCHIVE")
            DISK_MB=$(( (ISO_SIZE + KEYS_SIZE) / 1048576 + 150 ))
            DISK_MB=$(( ((DISK_MB + 63) / 64) * 64 ))  # Round up to 64MB alignment
            if [ "$DISK_MB" -lt 512 ]; then
              DISK_MB=512
            fi

            cyan "Creating disk image (''${DISK_MB}MB)..."
            truncate -s "''${DISK_MB}M" "$OUTPUT"

            # Install Ventoy (requires sudo for losetup)
            cyan "Installing Ventoy to disk image (requires sudo)..."
            if ! sudo -n true 2>/dev/null; then
              yellow "Sudo access required for Ventoy installation."
            fi

            LOOP_DEV=$(sudo losetup --show -f "$OUTPUT") || die "Failed to create loopback device"

            # Install Ventoy in non-interactive mode with GPT
            sudo ventoy -i -g "$LOOP_DEV" || {
              sudo losetup -d "$LOOP_DEV"
              die "Failed to install Ventoy"
            }

            # Detach loopback - remount with guestmount
            sudo losetup -d "$LOOP_DEV"
            LOOP_DEV=""

            # Mount with guestmount (FUSE, no root needed)
            cyan "Mounting Ventoy partition..."
            MOUNT_POINT=$(mktemp -d)
            sleep 1  # Give kernel time to release device

            guestmount -a "$OUTPUT" -m /dev/sda1 "$MOUNT_POINT" || die "Failed to mount Ventoy partition"

            # Copy ISO and keys
            cyan "Copying ISO to disk..."
            cp "$ISO_PATH" "$MOUNT_POINT/nixos.iso" || die "Failed to copy ISO"

            cyan "Copying key injection archive..."
            cp "$KEYS_ARCHIVE" "$MOUNT_POINT/keys.tar.gz" || die "Failed to copy keys archive"

            # Create Ventoy configuration
            cyan "Writing Ventoy configuration..."
            mkdir -p "$MOUNT_POINT/ventoy"

            cat > "$MOUNT_POINT/ventoy/ventoy.json" << 'VENTOY_EOF'
    {
      "control": [
        { "VTOY_MENU_TIMEOUT": "5" },
        { "VTOY_DEFAULT_IMAGE": "/nixos.iso" }
      ],
      "injection": [
        {
          "image": "/nixos.iso",
          "archive": "/keys.tar.gz"
        }
      ]
    }
    VENTOY_EOF

            # Show contents
            cyan "Disk contents:"
            ls -lh "$MOUNT_POINT"

            # Unmount
            cyan "Unmounting..."
            fusermount -u "$MOUNT_POINT"
            rmdir "$MOUNT_POINT"
            MOUNT_POINT=""

            # Cleanup temp archive
            rm -f "$KEYS_ARCHIVE"
            KEYS_ARCHIVE=""

            ACTUAL_SIZE=$(du -h "$OUTPUT" | cut -f1)

            echo ""
            green "✓ Ventoy disk created: $OUTPUT"
            echo "  Host: $HOST"
            echo "  ISO: $ISO_NAME"
            echo "  Size: $ACTUAL_SIZE"
            if ${helpers.var.notEmpty "users"}; then
              echo "  Keys: host + $users"
            else
              echo "  Keys: host only"
            fi
            echo ""
            cyan "Test with QEMU:"
            echo "  qemu-system-x86_64 -enable-kvm -m 4G \\"
            echo "    -drive file=$OUTPUT,format=raw"
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
