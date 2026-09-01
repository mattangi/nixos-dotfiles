{ pkgs, ... }:

{
  home.packages = [
    pkgs.alacritty
    pkgs.foot
    pkgs.ghostty
    pkgs.kitty
    pkgs.bottles
    pkgs.mupdf
    pkgs.nwg-look
    pkgs.wl-clipboard
    pkgs.adw-gtk3
    pkgs.yubikey-manager
    pkgs.yubico-piv-tool
    pkgs.bottom
    pkgs.btop
    pkgs.exiftool
    pkgs.fastfetch
    pkgs.fd
    pkgs.gdu
    pkgs.nitch
    pkgs.pv
    pkgs.rename
    pkgs.tree
  ];
}
