{
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
