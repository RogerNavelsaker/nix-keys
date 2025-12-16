# scripts/default.nix
# Note: nixos-anywhere moved to nix-repos (cross-repo script)
{ pkgs, pog }:
let
  call = f: import f { inherit pkgs pog; };
in
{
  genkey = call ./genkey.nix;
  deploy = call ./deploy.nix;
  create = call ./create.nix;
  inspect = call ./inspect.nix;
  list = call ./list.nix;
  show = call ./show.nix;
}
