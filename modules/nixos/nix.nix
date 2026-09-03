{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc.automatic = false;

  systemd.services.nix-generation-cleanup = {
    description = "Prune old NixOS generations and collect the Nix store";
    path = [ pkgs.nix ];
    script = ''
      set -euo pipefail

      # Nix +5 keeps the current and four preceding generations, plus any
      # generations newer than the current generation after a rollback.
      nix-env --profile /nix/var/nix/profiles/system --delete-generations +5
      nix-store --gc
    '';
    serviceConfig.Type = "oneshot";
  };

  systemd.timers.nix-generation-cleanup = {
    description = "Daily NixOS generation cleanup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
