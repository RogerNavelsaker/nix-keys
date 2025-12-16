# githooks.nix - Git hooks configuration using cachix/git-hooks.nix
_: {
  # Formatting (also validates syntax)
  nixfmt-rfc-style.enable = true;

  # Linting
  deadnix.enable = true;
  statix.enable = true;

  # Note: nix-syntax hook removed - nixfmt-rfc-style already validates syntax
  # and nix-instantiate --parse has SQLite contention issues in CI sandbox

  # Note: push is now allowed - private keys are GPG-encrypted via pass
  # Decryption requires Yubikey physical presence
}
