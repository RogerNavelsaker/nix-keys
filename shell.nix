# shell.nix
{
  pkgs,
  hooks,
  scripts,
}:

pkgs.devshell.mkShell {
  name = "nix-keys";

  motd = ''
    {202}🔑 SSH Key Management Environment (pass + Yubikey){reset}
    $(type -p menu &>/dev/null && menu)
  '';

  packages = with pkgs; [
    # Key generation
    openssh
    gh # GitHub CLI for uploading deploy keys
    fh

    # Pass (password-store) for encrypted key storage
    pass
    gnupg

    # Disk image tools
    ventoy # Ventoy USB/disk image creation
    libguestfs-with-appliance # guestmount for FUSE mounting

    # Archive tools
    gnutar
    gzip

    # Utilities
    coreutils
    findutils
    tree
    util-linux # losetup
    jq # JSON processing
  ];

  commands = [
    # Key Generation Commands
    {
      category = "generate";
      name = "genkey";
      help = "Generate SSH keys: genkey <host|flakehub|user> <name> (--help for details)";
      command = ''
        ${scripts.genkey}/bin/genkey "$@"
      '';
    }

    # GitHub Integration
    {
      category = "github";
      name = "deploy";
      help = "Manage GitHub deploy keys: deploy <add|remove|list> ... (--help for details)";
      command = ''
        ${scripts.deploy}/bin/deploy "$@"
      '';
    }

    # Disk Creation Commands
    {
      category = "disk";
      name = "create";
      help = "Create archive or Ventoy disk: create <archive|disk> <hostname> [iso-path] (--help)";
      command = ''
        ${scripts.create}/bin/create "$@"
      '';
    }

    # Disk Inspection Commands
    {
      category = "inspect";
      name = "inspect";
      help = "Show contents of disk or archive: inspect <file> (--help for details)";
      command = ''
        ${scripts.inspect}/bin/inspect "$@"
      '';
    }

    # Utility Commands
    {
      category = "info";
      name = "list";
      help = "List all generated keys (hosts and users)";
      command = ''
        ${scripts.list}/bin/list "$@"
      '';
    }
    {
      category = "info";
      name = "show";
      help = "Show keys for specific host or user: show <host|user> <name> (--help for details)";
      command = ''
        ${scripts.show}/bin/show "$@"
      '';
    }

    # Utilities
    {
      category = "utilities";
      package = "openssh";
    }
    {
      category = "utilities";
      package = "gh";
    }
    {
      category = "utilities";
      package = "pass";
    }
  ];

  devshell.startup = {
    git-hooks.text = hooks.shellHook;
    pass-env.text = ''
      export PASSWORD_STORE_DIR="./private"
    '';
  };
}
