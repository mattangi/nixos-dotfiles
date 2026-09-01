{ pkgs, ... }:

{
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

  environment.sessionVariables = {
    XMODIFIERS = "@im=fcitx";
    QT_IM_MODULE = "fcitx";
    GTK_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "fcitx";
  };
}
