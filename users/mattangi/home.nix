{
  config,
  pkgs,
  lib,
  ...
}:
let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  configs = {
    alacritty = "alacritty"; # cross platform
    bat = "bat"; # cross platform
    btop = "btop"; # cross platform
    fastfetch = "fastfetch"; # cross platform
    fcitx = "fcitx"; # linux specific
    fcitx5 = "fcitx5"; # linux specific
    foot = "foot"; # linux specific
    ghostty = "ghostty"; # cross platform.  linux: ghostty, nix-darwin: ghostty-bin
    "gtk-3.0" = "gtk-3.0"; # linux specific
    "gtk-4.0" = "gtk-4.0"; # linux specific
    hypr = "hypr"; # linux specific
    kitty = "kitty"; # cross platform
    noctalia = "noctalia"; # linux specific
    nvim = "nvim"; # cross platform
    qt5ct = "qt5ct"; # linux specific
    qt6ct = "qt6ct"; # linux specific
    superfile = "superfile"; # cross platform
    walls = "walls";
  };

in
{
  imports = [
    ../../modules/home/packages.nix
    ../../modules/home/development.nix
  ];

  home.username = "mattangi";
  home.homeDirectory = "/home/mattangi";
  home.stateVersion = "26.11";
  programs.zsh = import ../../config/zsh.nix { inherit config pkgs lib; };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.ripgrep.enable = true;
  programs.fzf.enable = true;
  programs.bat.enable = true;
  programs.eza.enable = true;
  programs.git = {
    enable = true;
    settings = {
      user.name = "Kevin Yoon";
      user.email = "mattangi@gmail.com";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      fetch.prune = true;
      pull.ff = "only";
      merge.conflictStyle = "zdiff3";
      rerere.enabled = true;
    };
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_sk";
        IdentitiesOnly = true;
      };
    };
  };

  programs.codex = {
    enable = true;
  };

  programs.firefox = {
    # dont install for nix-darwin
    enable = true;

    nativeMessagingHosts = [
      pkgs.pywalfox-native
    ];

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;
    };

    policies.ExtensionSettings = {
      # dont install for nix-darwin
      "pywalfox@frewacom.org" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/pywalfox/latest.xpi";
        installation_mode = "force_installed";
      };

      "extension@one-tab.com" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/onetab/latest.xpi";
        installation_mode = "force_installed";
      };
    };
  };

  home.file.".mozilla/native-messaging-hosts/pywalfox.json".text = builtins.toJSON {
    # dont install for nix-darwin
    name = "pywalfox";
    description = "Native messaging host for Pywalfox";
    path = "${pkgs.pywalfox-native}/bin/pywalfox";
    type = "stdio";
    allowed_extensions = [ "pywalfox@frewacom.org" ];
  };

  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
  }) configs;
  #home.file.".config/alacritty".source = ./config/alacritty;
}
