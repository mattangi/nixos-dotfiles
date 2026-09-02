{ pkgs, ... }:

{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  programs.zsh.enable = true;
  users.users."kyoon" = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "Kevin Yoon";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
