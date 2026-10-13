{
  # Minimal root flake — exists so tests/flake.nix can reference the repo
  # root as a `path:..` input (Nix requires flake.nix at any input root).
  # Real checks live in tests/: `nix flake check` from tests/ or here via
  # `nix build ./tests#checks.x86_64-linux.config`.
  description = "CachyOS/Arch multi-device dotfiles";
  outputs = { self }: { };
}
