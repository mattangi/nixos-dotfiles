{ pkgs, ... }:

{
  # hardware graphics acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # supports for steam/games
    extraPackages = with pkgs; [ ];
    extraPackages32 = with pkgs; [ ];
  };

  programs.steam = {
    enable = true;
  };
}
