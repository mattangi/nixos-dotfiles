{ pkgs, superfile, ... }: with pkgs;
[
  # essentials.  cross platform.  linux, nix-darwin
  vim

  # Terminal emulators

  # Utilities.  cross platform otherwise specified
  fetch # linux specific (pkgs-unstable specific)
  gcc # linux specific
  gnumake # linux specific
  pkg-config # linux specific
  lazygit
  lua5_1
  luarocks
  neovim
  nixd
  nixfmt
  nodejs
  python3
  superfile
  tree-sitter
  uv # linux specific

  # guis
  apple-cursor # linux specific
  feh # cross platform.  linux, nix-darwin

  #  polkit_gnome
  hyprpolkitagent # linux specific
  wineWow64Packages.stable # linux specific
]
