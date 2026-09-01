-- Hyprland/Wayland stuff
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- QT apps
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPT_PLATFORMTHEME", "qt5ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- Nvidia
-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("__GTX_VENDOR_LIBRARY_NAME", "nvidia")

--hl.env("GTK_THEME", "Catppuccin")
--hl.env("GTK_ICON_THEME", "Catppuccin")
--hl.env("XCURSOR_THEME", "Catppuccin")
--hl.env("XCURSOR_SIZE", "24")
--hl.env("HYPRCURSOR_SIZE", "24")
