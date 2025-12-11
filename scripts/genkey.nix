# scripts/genkey.nix
{ pkgs, pog }:

pog.pog {
  name = "genkey";
  version = "2.0.0";
  description = "Generate SSH keys for hosts and users (stored in pass)";

  arguments = [
    {
      name = "type";
      description = "key type: host, deploy, or user";
    }
    {
      name = "name";
      description = "hostname or username";
    }
  ];

  runtimeInputs = with pkgs; [
    openssh
    coreutils
    pass
    gnupg
  ];

  script = helpers: ''
    TYPE="$1"
    NAME="$2"

    export PASSWORD_STORE_DIR="./private"

    if ${helpers.var.empty "TYPE"}; then
      die "Error: Type required (host, deploy, or user)"
    fi

    if ${helpers.var.empty "NAME"}; then
      die "Error: Name required"
    fi

    # Create temp directory for key generation
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf $TEMP_DIR' EXIT

    case "$TYPE" in
      host)
        PUB_DIR="public/hosts/$NAME"
        PASS_PATH="hosts/$NAME/ssh_host_ed25519_key"
        KEY_FILE="$TEMP_DIR/ssh_host_ed25519_key"

        mkdir -p "$PUB_DIR"

        green "Generating SSH host key for: $NAME"
        ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -C "root@$NAME"

        cyan "Storing private key in pass (requires Yubikey)..."
        pass insert -m "$PASS_PATH" < "$KEY_FILE"

        mv "$KEY_FILE.pub" "$PUB_DIR/ssh_host_ed25519_key.pub"
        chmod 644 "$PUB_DIR/ssh_host_ed25519_key.pub"

        echo ""
        green "✓ SSH host key generated"
        echo "  Private: pass show $PASS_PATH"
        echo "  Public:  $PUB_DIR/ssh_host_ed25519_key.pub"
        echo ""
        cyan "Public key:"
        cat "$PUB_DIR/ssh_host_ed25519_key.pub"
        ;;

      deploy)
        PUB_DIR="public/hosts/$NAME"
        PASS_PATH="hosts/$NAME/deploy_key_ed25519"
        KEY_FILE="$TEMP_DIR/deploy_key_ed25519"

        mkdir -p "$PUB_DIR"

        green "Generating deploy key for: $NAME"
        ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -C "deploy@$NAME"

        cyan "Storing private key in pass (requires Yubikey)..."
        pass insert -m "$PASS_PATH" < "$KEY_FILE"

        mv "$KEY_FILE.pub" "$PUB_DIR/deploy_key_ed25519.pub"
        chmod 644 "$PUB_DIR/deploy_key_ed25519.pub"

        echo ""
        green "✓ Deploy key generated"
        echo "  Private: pass show $PASS_PATH"
        echo "  Public:  $PUB_DIR/deploy_key_ed25519.pub"
        echo ""
        cyan "Public key (add to GitHub/GitLab):"
        cat "$PUB_DIR/deploy_key_ed25519.pub"
        ;;

      user)
        PUB_DIR="public/home/$NAME"
        PASS_PATH="home/$NAME/id_ed25519"
        KEY_FILE="$TEMP_DIR/id_ed25519"

        mkdir -p "$PUB_DIR"

        green "Generating SSH key for user: $NAME"
        ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -C "$NAME@nixos"

        cyan "Storing private key in pass (requires Yubikey)..."
        pass insert -m "$PASS_PATH" < "$KEY_FILE"

        mv "$KEY_FILE.pub" "$PUB_DIR/id_ed25519.pub"
        chmod 644 "$PUB_DIR/id_ed25519.pub"

        echo ""
        green "✓ User SSH key generated"
        echo "  Private: pass show $PASS_PATH"
        echo "  Public:  $PUB_DIR/id_ed25519.pub"
        echo ""
        cyan "Public key:"
        cat "$PUB_DIR/id_ed25519.pub"
        ;;

      *)
        die "Error: Unknown type '$TYPE'. Valid types: host, deploy, user"
        ;;
    esac
  '';
}
