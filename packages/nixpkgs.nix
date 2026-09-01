{ pkgs, ... }: with pkgs;
[
  # essentials.  cross platform.  linux, nix-darwin

  # Terminal emulators

  # Utilities.  cross platform otherwise specified

  # guis

  #  polkit_gnome
  hyprpolkitagent # linux specific
  wineWow64Packages.stable # linux specific
]
