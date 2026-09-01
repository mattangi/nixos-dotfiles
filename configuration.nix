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

  # Noctalia requirements
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # yubikey support
  services.pcscd.enable = true;

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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "kr";
    variant = "kr104";
  };

  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;

    fcitx5 = {
      addons = with pkgs; [
        fcitx5-hangul
        fcitx5-gtk
        fcitx5-nord
      ];
      waylandFrontend = true;
    };
  };

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

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable dconf (required for GTK settings to persist)
  programs.dconf.enable = true;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = pkgs.callPackage ./packages/nixpkgs.nix {
    superfile = inputs.superfile.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
  # uv can install CLI binaries smoothly
  environment.localBinInPath = true;

  programs.noctalia = {
    # linux specific
    enable = true;
    recommendedServices.enable = true;
    systemd.enable = true;
  };

  # usb configs are linux specific
  services.udisks2.enable = true;
  services.devmon.enable = true;
  services.gvfs.enable = true;

  # polkit configs are linux specific
  security.polkit.enable = true;
  security.pam.services = {
    sudo.u2f = {
      enable = true;
      control = "sufficient";
    };

    polkit-1.u2f = {
      enable = true;
      control = "sufficient";
    };

    login.u2f = {
      enable = true;
      control = "sufficient";
    };

    #    greetd.u2f = {
    #      enable = true;
    #      control = "sufficient";
    #    };
  };

  systemd.services."polkit-agent-helper@".serviceConfig = {
    PrivateDevices = false;

    DeviceAllow = [
      "/dev/urandom r"
      "char-hidraw rw"
    ];

    ProtectHome = "read-only";
  };

  # Enable Pipewire for screencasting and audio server. Linux specific
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
  };

  # hyprland related configs are linux specific
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  xdg.portal.enable = true;

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    NIXOS_OZONE_HWP = "1";
    XMODIFIERS = "@im=fcitx";
    QT_IM_MODULE = "fcitx";
    GTK_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "fcitx";
  };

  environment.variables = {
    XCURSOR_THEME = "macOS";
    XCURSOR_SIZE = "24";
  };

  programs.noctalia-greeter = {
    enable = true;
    greeter-args = "";
    settings = {
      auth = {
        allow_empty_password = true;
      };
      cursor = {
        theme = "macOS";
        size = 24;
      };
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono # cross platform
    nerd-fonts.meslo-lg # cross platform
    nanum # linux specific
    noto-fonts-cjk-sans # linux specific
  ];

  # gnome related configs are linux specific
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

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
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  system.stateVersion = "26.11"; # Did you read the comment?

}
