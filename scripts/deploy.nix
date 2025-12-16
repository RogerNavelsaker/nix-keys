# scripts/deploy.nix
{ pkgs, pog }:

pog.pog {
  name = "deploy";
  version = "1.0.0";
  description = "Manage GitHub deploy keys";

  arguments = [
    {
      name = "action";
      description = "action: add, remove, or list";
    }
    {
      name = "hostname";
      description = "hostname (for add/remove)";
    }
    {
      name = "repo";
      description = "repository (owner/repo)";
    }
  ];

  flags = [
    {
      name = "rw";
      bool = true;
      description = "grant write access (default is read-only)";
    }
  ];

  runtimeInputs = with pkgs; [
    gh
    jq
    coreutils
  ];

  script = helpers: ''
    ACTION="$1"
    HOST="$2"
    REPO="$3"

    if ${helpers.var.empty "ACTION"}; then
      die "Error: Action required (add, remove, or list)"
    fi

    case "$ACTION" in
      add)
        if ${helpers.var.empty "HOST"} || ${helpers.var.empty "REPO"}; then
          die "Error: Hostname and repository required\nUsage: deploy add <hostname> <owner/repo> [--rw]"
        fi

        KEY_FILE="public/hosts/$HOST/deploy_key_ed25519.pub"

        if ${helpers.file.notExists "KEY_FILE"}; then
          die "Error: Deploy key not found: $KEY_FILE\nRun: genkey deploy $HOST"
        fi

        green "Uploading deploy key for '$HOST' to '$REPO'..."
        if ${helpers.flag "rw"}; then
          yellow "⚠ Granting WRITE access"
          gh repo deploy-key add "$KEY_FILE" \
            --repo "$REPO" \
            --title "Deploy key for $HOST (RW)" \
            --allow-write
        else
          cyan "✓ Read-only access (secure default)"
          gh repo deploy-key add "$KEY_FILE" \
            --repo "$REPO" \
            --title "Deploy key for $HOST (RO)"
        fi

        echo ""
        green "✓ Deploy key uploaded"
        ;;

      remove)
        if ${helpers.var.empty "HOST"} || ${helpers.var.empty "REPO"}; then
          die "Error: Hostname and repository required\nUsage: deploy remove <hostname> <owner/repo>"
        fi

        KEY_FILE="public/hosts/$HOST/deploy_key_ed25519.pub"

        if ${helpers.file.notExists "KEY_FILE"}; then
          die "Error: Deploy key not found: $KEY_FILE"
        fi

        green "Listing deploy keys for '$REPO'..."
        KEY_CONTENT=$(cat "$KEY_FILE" | cut -d' ' -f2)

        KEY_ID=$(gh repo deploy-key list --repo "$REPO" --json id,key | \
          jq -r ".[] | select(.key | contains(\"$KEY_CONTENT\")) | .id")

        if ${helpers.var.empty "KEY_ID"}; then
          die "Error: No matching deploy key found in repository\nThe key for '$HOST' might not be uploaded to '$REPO'"
        fi

        cyan "Removing deploy key (ID: $KEY_ID) from '$REPO'..."
        gh repo deploy-key delete "$KEY_ID" --repo "$REPO" --yes

        green "✓ Deploy key removed"
        ;;

      list)
        if ${helpers.var.empty "HOST"}; then
          # HOST is actually REPO for list command
          die "Error: Repository required\nUsage: deploy list <owner/repo>"
        fi
        # For list, the second arg is the repo
        REPO="$HOST"

        green "Deploy keys for '$REPO':"
        echo ""
        gh repo deploy-key list --repo "$REPO"
        ;;

      *)
        die "Error: Unknown action '$ACTION'. Valid actions: add, remove, list"
        ;;
    esac
  '';
}
