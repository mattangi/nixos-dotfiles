{ pkgs, ... }:
let
  u2f-register = pkgs.writeShellApplication {
    name = "u2f-register";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.hostname
      pkgs.pam_u2f
    ];
    text = ''
      set -euo pipefail

      if [ "$(id -u)" -eq 0 ]; then
        echo "u2f-register must be run as a regular user, not root." >&2
        exit 1
      fi

      username="$(id -un)"
      hostname="$(hostname)"
      origin="pam://$hostname"
      u2f_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/Yubico"
      u2f_file="$u2f_dir/u2f_keys"

      if [ -e "$u2f_file" ] || [ -L "$u2f_file" ]; then
        echo "Refusing to overwrite existing U2F mapping: $u2f_file" >&2
        exit 1
      fi

      if [ ! -d "$u2f_dir" ]; then
        mkdir -p "$u2f_dir"
      fi
      chmod 0700 "$u2f_dir"

      temporary_file="$(mktemp "$u2f_dir/.u2f_keys.XXXXXX")"
      cleanup() {
        rm -f "$temporary_file"
      }
      trap cleanup EXIT

      echo "Registering a YubiKey for $username on $hostname."
      echo "You may be prompted for the YubiKey PIN and/or asked to touch the key."
      echo

      pamu2fcfg \
        -u "$username" \
        -o "$origin" \
        -i "$origin" \
        >"$temporary_file"

      if [ ! -s "$temporary_file" ]; then
        echo "Enrollment failed: pamu2fcfg produced no U2F mapping." >&2
        exit 1
      fi

      chmod 0600 "$temporary_file"
      mv --no-clobber "$temporary_file" "$u2f_file"
      if [ -e "$temporary_file" ]; then
        echo "Refusing to overwrite U2F mapping created during enrollment: $u2f_file" >&2
        exit 1
      fi
      trap - EXIT

      echo "YubiKey U2F mapping created: $u2f_file"
    '';
  };
in
{
  environment.systemPackages = [
    pkgs.pam_u2f
    u2f-register
  ];

  services.pcscd.enable = true;

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
}
