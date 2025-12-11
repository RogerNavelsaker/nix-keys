# scripts/show.nix
{ pkgs, pog }:

pog.pog {
  name = "show";
  version = "2.0.0";
  description = "Show keys for specific host or user (public keys from public/, private in pass)";

  arguments = [
    {
      name = "type";
      description = "type: host or user";
    }
    {
      name = "name";
      description = "hostname or username";
    }
  ];

  runtimeInputs = with pkgs; [
    coreutils
    tree
  ];

  script = helpers: ''
    TYPE="$1"
    NAME="$2"

    if ${helpers.var.empty "TYPE"}; then
      die "Error: Type required (host or user)"
    fi

    if ${helpers.var.empty "NAME"}; then
      die "Error: Name required"
    fi

    case "$TYPE" in
      host)
        if ! [ -d "public/hosts/$NAME" ]; then
          die "Error: Host not found: $NAME"
        fi

        green "=== Keys for host: $NAME ==="
        echo ""

        if [ -f "public/hosts/$NAME/ssh_host_ed25519_key.pub" ]; then
          cyan "SSH Host Key (ed25519):"
          cat "public/hosts/$NAME/ssh_host_ed25519_key.pub"
          echo "  Private: PASSWORD_STORE_DIR=./private pass show hosts/$NAME/ssh_host_ed25519_key"
          echo ""
        fi

        if [ -f "public/hosts/$NAME/deploy_key_ed25519.pub" ]; then
          cyan "Deploy Key (ed25519):"
          cat "public/hosts/$NAME/deploy_key_ed25519.pub"
          echo "  Private: PASSWORD_STORE_DIR=./private pass show hosts/$NAME/deploy_key_ed25519"
          echo ""
        fi

        cyan "Public key files:"
        tree "public/hosts/$NAME" 2>/dev/null || ls -la "public/hosts/$NAME"
        ;;

      user)
        if ! [ -d "public/home/$NAME" ]; then
          die "Error: User not found: $NAME"
        fi

        green "=== Keys for user: $NAME ==="
        echo ""

        if [ -f "public/home/$NAME/id_ed25519.pub" ]; then
          cyan "SSH Key (ed25519):"
          cat "public/home/$NAME/id_ed25519.pub"
          echo "  Private: PASSWORD_STORE_DIR=./private pass show home/$NAME/id_ed25519"
          echo ""
        fi

        cyan "Public key files:"
        tree "public/home/$NAME" 2>/dev/null || ls -la "public/home/$NAME"
        ;;

      *)
        die "Error: Unknown type '$TYPE'. Valid types: host, user"
        ;;
    esac
  '';
}
