{ pkgs, ... }:

{
  home.packages = [
    pkgs.neovim
    pkgs.nixd
    pkgs.nixfmt
    pkgs.uv
    pkgs.lazygit
    pkgs.gcc
    pkgs.gnumake
    pkgs.pkg-config
    pkgs.lua5_1
    pkgs.luarocks
    pkgs.nodejs
    pkgs.python3
    pkgs.tree-sitter
  ];
}
