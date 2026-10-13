{
  # Repo root flake — hosts repo-wide static checks (the NixOS VM tests
  # live in tests/, which is its own flake: `nix flake check` there).
  # Run: `nix build .#checks.x86_64-linux.opencode-config -L`
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      checks.${system}.opencode-config = import tests/config.nix { inherit pkgs self; };
    };
}
