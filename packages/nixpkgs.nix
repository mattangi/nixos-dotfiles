{ pkgs, ... }: with pkgs;
[
  # essentials.  cross platform.  linux, nix-darwin

  # Terminal emulators

  # Utilities.  cross platform otherwise specified
  fetch # linux specific (pkgs-unstable specific)
  gcc # linux specific
  gnumake # linux specific
  pkg-config # linux specific
  lua5_1
  luarocks
  nodejs
  python3
  tree-sitter

  # guis
  apple-cursor # linux specific

  #  polkit_gnome
  hyprpolkitagent # linux specific
  wineWow64Packages.stable # linux specific
]
