{ inputs, pkgs, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14s-amd-gen4
  ];

  environment.systemPackages = with pkgs; [
    amdgpu_top
    nvtopPackages.amd
    radeontop
  ];
}
