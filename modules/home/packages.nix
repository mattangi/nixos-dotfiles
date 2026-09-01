{ pkgs, ... }:

{
  home.packages = [
    pkgs.wget
    pkgs.zip
    pkgs.unzip
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
