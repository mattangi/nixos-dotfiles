{ pkgs, ... }:

{
  home.packages = [
    pkgs.neovim
    pkgs.nixd
    pkgs.nixfmt
    pkgs.uv
    pkgs.lazygit
  ];
}
