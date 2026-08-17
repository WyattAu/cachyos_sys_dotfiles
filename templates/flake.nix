{
  description = "Development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Languages
            rustup
            nodejs
            python3
            go

            # Tools
            git
            curl
            jq
            ripgrep
            fd
            bat
            eza
            fzf
            zoxide
            lazygit

            # Dev
            cmake
            ninja
            clang
            gdb
            pkg-config
            openssl

            # Formatters
            stylua
            ruff
            shfmt
            taplo
            prettier
          ];

          shellHook = ''
            echo "╔══════════════════════════════════╗"
            echo "║   Development Environment Ready  ║"
            echo "╚══════════════════════════════════╝"
            echo "Rust:   $(rustc --version 2>/dev/null || echo 'not installed')"
            echo "Node:   $(node --version 2>/dev/null || echo 'not installed')"
            echo "Python: $(python3 --version 2>/dev/null || echo 'not installed')"
            echo "Go:     $(go version 2>/dev/null || echo 'not installed')"
          '';
        };
      }
    );
}
