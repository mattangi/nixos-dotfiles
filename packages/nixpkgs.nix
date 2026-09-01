{ pkgs, ... }: with pkgs;
[
  # essentials.  cross platform.  linux, nix-darwin

  # Terminal emulators

  # Utilities.  cross platform otherwise specified
  fetch # linux specific (pkgs-unstable specific)

  # guis
  apple-cursor # linux specific

  #  polkit_gnome
  hyprpolkitagent # linux specific
  wineWow64Packages.stable # linux specific
]
