{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix # this is not necessary for nix-darwin
    ./machine.nix
    ../../modules/nixos/nix.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/input.nix
    ../../modules/nixos/fonts.nix
    ../../modules/nixos/laptop.nix
    ../../modules/nixos/security.nix
    ../../modules/nixos/desktop.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # hardware graphics acceleration
  hardware.graphics = {
    # hardware graphics acceleration
    enable = true;
    enable32Bit = true; # supports for steam/games
    extraPackages = with pkgs; [ ];
    extraPackages32 = with pkgs; [ ];
  };

  networking.hostName = "thinkpad"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Seoul";

  # all i18n and icitx5 configurations are specific for linux
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  #  i18n.extraLocaleSettings = {
  #    LC_ADDRESS = "ko_KR.UTF-8";
  #    LC_IDENTIFICATION = "ko_KR.UTF-8";
  #    LC_MEASUREMENT = "ko_KR.UTF-8";
  #    LC_MONETARY = "ko_KR.UTF-8";
  #    LC_NAME = "ko_KR.UTF-8";
  #    LC_NUMERIC = "ko_KR.UTF-8";
  #    LC_PAPER = "ko_KR.UTF-8";
  #    LC_TELEPHONE = "ko_KR.UTF-8";
  #    LC_TIME = "ko_KR.UTF-8";
  #  };

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

  # List packages installed in system profile. To search, run:
  environment.systemPackages = pkgs.callPackage ../../packages/nixpkgs.nix {
    superfile = inputs.superfile.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
  # uv can install CLI binaries smoothly
  environment.localBinInPath = true;

  programs.steam = {
    # cross platform
    enable = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.11"; # Did you read the comment?

}
