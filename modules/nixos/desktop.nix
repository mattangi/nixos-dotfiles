{ pkgs, ... }:

{
  # Enable dconf (required for GTK settings to persist)
  programs.dconf.enable = true;

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
}
