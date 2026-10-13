{
  description = "System configuration tests";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # The repo root (parent of tests/) — path input, no flake.nix there,
    # so it is treated as a plain source tree and sees uncommitted files.
    dotfiles.url = "path:..";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      checks.${system} = {
        system = pkgs.testers.runNixOSTest (import ./system.nix { inherit pkgs; });
        roles = pkgs.testers.runNixOSTest (import ./roles.nix { inherit pkgs; });
        config = import ./config.nix { inherit pkgs; repo = self.inputs.dotfiles; };
      };
    };
}
