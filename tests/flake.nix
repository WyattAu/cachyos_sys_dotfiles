{
  description = "System configuration tests";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      checks.${system} = {
        system = pkgs.testers.runNixOSTest (import ./system.nix { inherit pkgs; });
        roles = pkgs.testers.runNixOSTest (import ./roles.nix { inherit pkgs; });
      };
    };
}
