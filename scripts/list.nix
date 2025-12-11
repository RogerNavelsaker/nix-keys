# scripts/list.nix
{ pkgs, pog }:

pog.pog {
  name = "list";
  version = "2.0.0";
  description = "List all generated keys (public keys from public/, private in pass)";

  runtimeInputs = with pkgs; [
    coreutils
  ];

  script = _: ''
    green "=== Hosts ==="
    if [ -d "public/hosts" ]; then
      for host_dir in public/hosts/*; do
        if [ -d "$host_dir" ]; then
          host=$(basename "$host_dir")
          echo ""
          cyan "Host: $host"

          if [ -f "$host_dir/ssh_host_ed25519_key.pub" ]; then
            echo "  SSH Host Key: $(cat "$host_dir/ssh_host_ed25519_key.pub")"
          fi

          if [ -f "$host_dir/deploy_key_ed25519.pub" ]; then
            echo "  Deploy Key: $(cat "$host_dir/deploy_key_ed25519.pub")"
          fi
        fi
      done
    else
      echo "  (none)"
    fi

    echo ""
    green "=== Users ==="
    if [ -d "public/home" ]; then
      for user_dir in public/home/*; do
        if [ -d "$user_dir" ]; then
          user=$(basename "$user_dir")
          echo ""
          cyan "User: $user"

          if [ -f "$user_dir/id_ed25519.pub" ]; then
            echo "  SSH Key: $(cat "$user_dir/id_ed25519.pub")"
          fi
        fi
      done
    else
      echo "  (none)"
    fi

    echo ""
    yellow "Note: Private keys stored in pass (requires Yubikey)"
    echo "  Use: PASSWORD_STORE_DIR=./private pass show <path>"
  '';
}
