{ pkgs, ... }:

{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  programs.zsh.enable = true;
  users.users."mattangi" = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "mattangi";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      tree # per-user pkgs
    ];
  };
}
