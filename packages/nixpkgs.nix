{ pkgs, superfile, ... }: with pkgs;
[
  # essentials.  cross platform.  linux, nix-darwin
  git
  oh-my-zsh
  vim
  zsh
  zsh-powerlevel10k
  zsh-autosuggestions
  zsh-syntax-highlighting

  # Terminal emulators

  # Utilities.  cross platform otherwise specified
  bat
  eza
  fzf
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
  pam_u2f
  python3
  ripgrep
  superfile
  tree-sitter
  uv # linux specific
  zoxide

  # guis
  apple-cursor # linux specific
  feh # cross platform.  linux, nix-darwin

  #  polkit_gnome
  hyprpolkitagent # linux specific
  steam # cross platform.  linux, nix-darwin
  wineWow64Packages.stable # linux specific
]
