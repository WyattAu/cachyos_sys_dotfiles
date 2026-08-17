{
  description = "System configuration tests";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-test.url = "github:NixOS/nixpkgs/nixos-unstable#nixosTests";
  };

  outputs = { self, nixpkgs, ... }: {
    packages.x86_64-linux.system-tests = import ./system.nix {
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    };

    packages.x86_64-linux.role-tests = import ./roles.nix {
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    };

    checks.x86_64-linux = {
      system = self.packages.x86_64-linux.system-tests;
      roles = self.packages.x86_64-linux.role-tests;
    };
  };
}
