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
  alacritty # cross platform.  linux, nix-darwin
  foot # linux specific
  ghostty # cross platform.  linux, nix-darwin (ghostty-bin)
  kitty # default emulator. cross platform.  linux, nix-darwin

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
  wl-clipboard # linux specific
  yubico-piv-tool
  yubikey-manager
  zoxide

  # guis
  adw-gtk3 # linux specific
  apple-cursor # linux specific
  bottles # linux specific
  feh # cross platform.  linux, nix-darwin
  mupdf # cross platform.  linux, nix-darwin
  nwg-look # linux specific

  #  polkit_gnome
  hyprpolkitagent # linux specific
  steam # cross platform.  linux, nix-darwin
  wineWow64Packages.stable # linux specific
]
