{ inputs, pkgs, ... }:

{
  # Razer Blade 15 Advanced (Mid 2019), model RZ09-0301.
  #
  # This machine uses an Intel iGPU plus an NVIDIA RTX 20-series Max-Q dGPU.
  # Before the first activation on the actual Razer, verify the PCI bus IDs with:
  #
  #   lspci -nn | grep -E "VGA|3D"
  #
  # The expected layout for this model is:
  #   Intel  -> 00:02.0 -> PCI:0:2:0
  #   NVIDIA -> 01:00.0 -> PCI:1:0:0

  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # Enable the proprietary NVIDIA driver stack while keeping the Intel iGPU
  # as the normal low-power renderer. Use `nvidia-offload <command>` when an
  # application should run on the NVIDIA GPU.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    # RZ09-0301 uses a Turing-generation RTX 20-series GPU. Keep the
    # proprietary kernel module for the initial known-good configuration.
    open = false;

    powerManagement = {
      enable = true;
      finegrained = true;
    };

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Machine-specific NVIDIA diagnostic tool, analogous to the AMD diagnostics
  # kept in the ThinkPad machine module.
  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
  ];
}
