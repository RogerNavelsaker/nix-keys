# githooks.nix - Git hooks configuration using cachix/git-hooks.nix
{ pkgs }:
{
  # Formatting
  nixfmt-rfc-style.enable = true;

  # Linting
  deadnix.enable = true;
  statix.enable = true;

  # Syntax validation
  nix-syntax = {
    enable = true;
    name = "nix-syntax";
    description = "Validate Nix syntax with nix-instantiate --parse";
    entry = "${pkgs.nix}/bin/nix-instantiate --parse";
    files = "\\.nix$";
    pass_filenames = true;
  };

  # Note: push is now allowed - private keys are GPG-encrypted via pass
  # Decryption requires Yubikey physical presence
}
