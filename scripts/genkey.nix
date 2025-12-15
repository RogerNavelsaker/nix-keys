# scripts/genkey.nix
{ pkgs, pog }:

pog.pog {
  name = "genkey";
  version = "3.0.0";
  description = "Generate SSH keys and store FlakeHub tokens (stored in pass)";

  arguments = [
    {
      name = "type";
      description = "key type: host, flakehub, or user";
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

    export PASSWORD_STORE_DIR="$PWD/private"

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

      flakehub)
        PASS_PATH="hosts/$NAME/flakehub_token"

        green "Storing FlakeHub token for: $NAME"
        echo ""
        cyan "Generate a token at: https://flakehub.com/user/settings?editview=tokens"
        echo "Paste the token below (will be stored in pass, requires Yubikey):"
        echo ""

        pass insert "$PASS_PATH"

        echo ""
        green "✓ FlakeHub token stored"
        echo "  Retrieve: pass show $PASS_PATH"
        echo ""
        cyan "Usage: determinate-nixd login token --token-file <(pass show $PASS_PATH)"
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
        die "Error: Unknown type '$TYPE'. Valid types: host, flakehub, user"
        ;;
    esac
  '';
}
