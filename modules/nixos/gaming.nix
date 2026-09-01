{ pkgs, ... }:

{
  # hardware graphics acceleration
  hardware.graphics = {
    # hardware graphics acceleration
    enable = true;
    enable32Bit = true; # supports for steam/games
    extraPackages = with pkgs; [ ];
    extraPackages32 = with pkgs; [ ];
  };

  programs.steam = {
    # cross platform
    enable = true;
  };
}
