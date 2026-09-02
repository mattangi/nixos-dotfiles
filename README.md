# NixOS configuration

[한국어](README.ko.md)

This repository manages a declarative NixOS system, including per-host configuration, NixOS user accounts, Home Manager profiles, editable application dotfiles, and a bootstrap workflow for adopting additional machines.

The currently supported platform is **NixOS on x86_64-linux**. The bootstrap does not support ARM or other architectures, and nix-darwin/macOS is not currently supported.

## Repository structure

```text
.
├── bootstrap/
│   ├── apply
│   ├── register-host
│   └── render-template
├── config/
├── hosts/
│   ├── registry.nix
│   ├── thinkpad/
│   │   ├── default.nix
│   │   ├── hardware-configuration.nix
│   │   └── machine.nix
│   └── razer/
│       ├── default.nix
│       ├── hardware-configuration.nix
│       └── machine.nix
├── modules/
│   ├── home/
│   └── nixos/
├── templates/
│   ├── host/
│   └── user/
├── users/
│   ├── mattangi/
│   │   ├── default.nix
│   │   └── home.nix
│   └── kyoon/
│       ├── default.nix
│       └── home.nix
├── flake.nix
└── flake.lock
```

The main layers have deliberately separate responsibilities:

- `hosts/<host>/default.nix` assembles one host. It selects imports and contains instantiated host policy such as the bootloader, hostname, timezone, locale, `system.stateVersion`, and selected NixOS user.
- `hosts/<host>/machine.nix` contains intentionally hand-curated model- or machine-specific policy. Newly bootstrapped hosts start with a minimal empty module because bootstrap does not guess this policy.
- `hosts/<host>/hardware-configuration.nix` is generated from the actual current machine. It contains detected filesystems, storage, kernel modules, and similar installation-specific state. Keep it separate from curated `machine.nix` policy rather than mixing the two responsibilities.
- `hosts/registry.nix` explicitly associates each host with its primary user and Nix system. Only hosts listed in this registry become `nixosConfigurations.<host>` outputs; host directories are not discovered automatically.
- `modules/nixos/` contains reusable NixOS policy and feature modules, including Nix settings, networking, audio, input methods, fonts, laptop infrastructure, security, desktop/session infrastructure, gaming/graphics, and baseline system packages.
- `users/<user>/default.nix` defines the NixOS account: username, normal-user status, login shell, description, and system groups.
- `users/<user>/home.nix` assembles the user's Home Manager profile, identity, applications, and dotfile mappings.
- `modules/home/` contains reusable Home Manager package policy for user applications and persistent editor/development dependencies.
- `config/` contains live, editable application configuration.

The currently tracked physical hosts are:

- `thinkpad`: Lenovo ThinkPad T14s AMD Gen 4, with primary user `mattangi`.
- `razer`: Razer Blade 15 Advanced, model RZ09-0301, with primary user `kyoon`.

These relationships come from `hosts/registry.nix`. Detailed hardware policy belongs in each host's `machine.nix`, not in this inventory.

### Editable dotfiles

Home Manager intentionally exposes application configuration with `config.lib.file.mkOutOfStoreSymlink`. The source remains editable under:

```text
~/nixos-dotfiles/config
```

It is not copied into immutable Nix-store-managed files. Applications and plugin managers can therefore update their configuration while the repository remains the source of truth.

## Required repository location

The repository must be located at:

```text
/home/<user>/nixos-dotfiles
```

For example:

```text
/home/alice/nixos-dotfiles
```

This is required because the Home Manager profile derives its editable dotfile root from:

```nix
${config.home.homeDirectory}/nixos-dotfiles/config
```

`bootstrap/apply` enforces this invariant. Do not clone the repository to an arbitrary location and bypass the failure: the resulting out-of-store links would point at the wrong directory.

## Adopting a NixOS machine

Bootstrap is an adoption workflow for an **already installed and currently booted NixOS system**. It creates and validates repository configuration for that system. It is not a bare-metal installer: it does not partition disks, install NixOS, or replace the running configuration automatically.

### Prerequisites

Immediately before bootstrap, the machine must have:

- NixOS installed and currently running.
- An `x86_64-linux` system.
- A normal, non-root user account with `sudo` access for the later manual activation.
- Working network access for cloning the repository and evaluating flake inputs.
- Standard NixOS tools, including `nix`, `nixos-generate-config`, and `nixos-rebuild`.
- `git`, which is required to clone this repository.
- `pciutils`, which provides `lspci` for the bootstrap hardware report.

`vim` or another text editor is strongly recommended for reviewing and curating the generated `hosts/<host>/machine.nix` before first activation. `wget` and `unzip` are useful convenience or recovery tools, but `bootstrap/apply` does not depend on them.

Do not run bootstrap as root. It intentionally refuses root execution and never invokes `sudo` internally.

The final repository configuration enables flakes declaratively. Flakes and `nix-command` do not need to be globally enabled before bootstrap; the script supplies the temporary experimental-feature setting needed for its own initial validation.

### Clone the repository

On a minimal fresh NixOS installation, obtain the bootstrap tools temporarily without first editing `/etc/nixos/configuration.nix`:

```bash
nix-shell -p git pciutils vim
```

From that package shell, clone to the required location:

```bash
cd ~
git clone https://github.com/mattangi/nixos-dotfiles.git
cd ~/nixos-dotfiles
```

After the first successful activation, the repository installs its normal baseline tools declaratively through `modules/nixos/base-packages.nix`.

### Run bootstrap

The simplest interactive invocation is:

```bash
./bootstrap/apply
```

To display the supported options without making changes:

```bash
./bootstrap/apply --help
```

When omitted, bootstrap discovers or proposes:

- The current static hostname.
- The current user.
- The machine architecture.

It prompts for missing identity information when a new repository user must be created.

To adopt another host for an existing repository user:

```bash
./bootstrap/apply \
  --host razer \
  --user kyoon
```

This is the command used for the successfully tested Razer adoption. If both files for an existing user are complete, as they are under `users/kyoon/`, bootstrap reuses them unchanged. Name and email are neither required nor accepted when reusing an existing user.

To instantiate a new user:

```bash
./bootstrap/apply \
  --host desktop \
  --user alice \
  --name "Alice Example" \
  --email "alice@example.com"
```

This creates both:

```text
users/alice/default.nix
users/alice/home.nix
```

The selected user must be the normal user currently running bootstrap.

For non-interactive use, add:

```text
--yes
```

`--yes` skips only the final confirmation. It does not force overwrites, bypass validation or architecture checks, replace existing hosts/users, or weaken any conflict checks.

## What bootstrap does

`bootstrap/apply` performs these steps in order:

1. Validates the repository layout and required tools.
2. Discovers and validates the host, current user, and x86_64 architecture.
3. Enforces the repository-location invariant.
4. Checks host, user, registry, metadata, and wallpaper-path conflicts.
5. Checks effective write access for every destination this run plans to change.
6. Displays the planned host, user, paths, and fixed template defaults, then asks for confirmation.
7. Renders host templates into temporary staging.
8. Renders both user templates only when the user is new.
9. Creates a generic, intentionally empty `machine.nix`.
10. Generates hardware configuration with:

    ```bash
    nixos-generate-config --show-hardware-config
    ```

11. Collects safe local machine metadata.
12. Ensures the local `config/walls/` source directory exists.
13. Publishes the new host/user/metadata files without overwriting existing paths.
14. Registers the host through `bootstrap/register-host`.
15. Checks the working-tree flake and evaluates the new host's system derivation.
16. Stops.

**Bootstrap does not activate the system.**

The Razer host has been tested on physical hardware through repository cloning, bootstrap generation, hardware generation, `machine.nix` preparation, flake validation, build, `nixos-rebuild test`, and `nixos-rebuild switch`.

## What bootstrap does not do

Bootstrap does not:

- Run `nixos-rebuild switch` or `nixos-rebuild boot`.
- Run `home-manager switch`.
- Reboot or restart services or the desktop session.
- Modify `/etc/nix/nix.conf`.
- Install NixOS onto an empty disk or partition storage.
- Automatically select a `nixos-hardware` machine profile.
- Automatically configure CPU/GPU tuning or machine-specific quirks.
- Register a YubiKey or modify PAM/authentication state.
- Invoke an external AI service.
- Bootstrap secrets, keys, passwords, or tokens.
- Stage, commit, or push Git changes.
- Create or switch Git branches.
- Overwrite an existing host or user.
- Perform automatic rollback after publication.

## Generated host layout

Adopting a host named `desktop` creates:

```text
hosts/desktop/
├── default.nix
├── hardware-configuration.nix
└── machine.nix
```

- `default.nix` assembles the shared modules, selected user, hostname, and project defaults.
- `hardware-configuration.nix` is generated from the current installation by `nixos-generate-config --show-hardware-config`. It represents detected installation and hardware state; do not put curated model tuning in it.
- `machine.nix` starts as a minimal empty module and is the place for deliberate model policy.

Bootstrap also adds an explicit registry entry equivalent to:

```nix
desktop = {
  user = "alice";
  system = "x86_64-linux";
};
```

`bootstrap/register-host` is the controlled writer for that registry entry.

## Preparing `machine.nix` before the first activation

After:

```bash
./bootstrap/apply --host <host> --user <user>
```

bootstrap intentionally creates a minimal `hosts/<host>/machine.nix`. It must not guess GPU drivers, hardware profiles, PRIME topology, CPU tuning, or model-specific quirks.

Before the first `nixos-rebuild switch`, review:

```text
.bootstrap/<host>/hardware-report.txt
hosts/<host>/hardware-configuration.nix
```

You may also inspect the live hardware directly:

```bash
lspci -nn
lscpu
```

Use this information to decide which of these cases applies:

1. **A known-good machine configuration already exists.** Replace the bootstrap-created empty `machine.nix` with that curated file before the first build. Do not blindly copy policy from a different model.
2. **The machine is new or unknown.** Research appropriate settings from the generated report, generated hardware configuration, and live hardware information. `machine.nix` may contain verified `nixos-hardware` imports, CPU-specific configuration, GPU driver policy, NVIDIA PRIME configuration, Intel or AMD graphics policy, power or thermal settings, model-specific kernel parameters, firmware or device quirks, and host-specific diagnostic packages. ChatGPT or Codex can help analyze the hardware information and propose a module, but the user must review the result; bootstrap never invokes an external AI service automatically.
3. **No machine-specific configuration is needed.** The minimal generated `machine.nix` may remain empty.

Keep the responsibilities separate:

```text
hardware-configuration.nix = generated detected installation/hardware state
machine.nix                = intentionally maintained model-specific policy
```

Do not merge curated machine policy into `hardware-configuration.nix`. As a real example, the Razer host's Intel/NVIDIA PRIME policy was prepared in `hosts/razer/machine.nix` before its first activation.

## Local bootstrap metadata

Bootstrap retains local diagnostic state under:

```text
.bootstrap/<host>/
├── hardware-configuration.nix.tmp
├── hardware-report.txt
└── inputs.txt
```

- `hardware-configuration.nix.tmp` is the exact generated hardware configuration used for publication.
- `hardware-report.txt` contains architecture, hostname, selected DMI model fields, CPU details, and PCI devices.
- `inputs.txt` records the host/user/system inputs and template defaults.

`.bootstrap/` is intentionally Git-ignored. It may contain hardware details and filesystem UUIDs from the generated hardware configuration, so treat it as local diagnostic state—not as a portable shared configuration source or secret storage.

Bootstrap deliberately avoids collecting serial numbers, product UUIDs, YubiKey/U2F data, credentials, SSH keys, passwords, and tokens.

## Wallpapers

The editable wallpaper source is:

```text
config/walls/
```

Home Manager exposes that source through an out-of-store link at:

```text
~/.config/walls
```

Noctalia also uses `~/.config/walls`. The source directory is intentionally Git-ignored. Bootstrap creates an empty `config/walls/` if it is absent, but never adds or changes wallpaper files.

If `~/.config/walls` already exists as an ordinary directory before the first Home Manager activation, inspect and preserve its contents first. Home Manager intends to manage that path as a link. Do not delete or replace the existing directory without deciding how its files should be retained.

## Review changes before activation

Bootstrap leaves all changes unstaged. Start with:

```bash
git status
git status --short
git diff
```

Normal `git diff` does not show the contents of new untracked files. Review the newly generated files directly as well, especially:

- `hosts/<host>/default.nix`
- `hosts/<host>/hardware-configuration.nix`
- `hosts/<host>/machine.nix`
- New `users/<user>/` files, if created
- `hosts/registry.nix`

Do not stage or commit merely because bootstrap completed. Review and validate first.

## Repeat validation manually

Use the working-tree path form because generated files may still be untracked:

```bash
nix \
  --option experimental-features "nix-command flakes" \
  flake check 'path:.' \
  --no-build \
  --no-write-lock-file
```

Then evaluate the selected host, replacing `<host>`:

```bash
nix \
  --option experimental-features "nix-command flakes" \
  eval \
  "path:.#nixosConfigurations.<host>.config.system.build.toplevel.drvPath" \
  --raw \
  --no-write-lock-file
```

`path:.` includes untracked working-tree files. A normal Git-backed flake reference may omit them.

The temporary experimental-feature option is needed when the currently running NixOS generation has not yet activated this repository's declarative Nix settings. Do not edit `/etc/nix/nix.conf` as a workaround.

## First activation

Before activation:

1. Inspect all generated files.
2. Curate `hosts/<host>/machine.nix` when the machine needs model-specific policy.
3. Understand and preserve any existing `~/.config/walls` directory.
4. Repeat the flake check and derivation evaluation above.

> **Warning:** The following command is the point where the running system is actually changed. Bootstrap never runs it.

Immediately after bootstrap, the generated host and possibly user files are untracked. From the repository root, use the explicit path flake so those working-tree files are included, and progress through build, test activation, and persistent activation deliberately:

```bash
sudo nixos-rebuild build --flake 'path:.#<host>' \
  --option experimental-features "nix-command flakes"
sudo nixos-rebuild test --flake 'path:.#<host>' \
  --option experimental-features "nix-command flakes"
sudo nixos-rebuild switch --flake 'path:.#<host>' \
  --option experimental-features "nix-command flakes"
```

`build` creates the system without activating it. `test` activates it without making it the boot default. `switch` activates it and updates the default system generation. None of these commands reboots automatically.

After the first successful activation, this repository declaratively enables:

```nix
nix.settings.experimental-features = [
  "nix-command"
  "flakes"
];
```

Subsequent flake commands should therefore no longer need the temporary feature option. Do not add imperative settings to `/etc/nix/nix.conf`.

After the first successful activation, perform the YubiKey enrollment described under [Authentication notes](#authentication-notes).

The tested adoption sequence is:

```text
bootstrap/apply
→ inspect hardware report
→ prepare/review machine.nix
→ nixos-rebuild build
→ nixos-rebuild test
→ nixos-rebuild switch
→ u2f-register
→ test sudo and greeter YubiKey authentication
```

## Normal update and rebuild workflow

On an already configured machine, review local work before pulling changes made elsewhere:

```bash
cd ~/nixos-dotfiles
git status
git pull --ff-only origin main
```

Local uncommitted changes may overlap incoming work, so inspect them before pulling.

To update pinned flake inputs and validate the result:

```bash
nix flake update
nix flake check
```

`nix flake update` changes `flake.lock`. Review that change and commit it intentionally only after successful testing.

Activate the configuration for the current host:

```bash
sudo nixos-rebuild switch --flake .#thinkpad
```

or:

```bash
sudo nixos-rebuild switch --flake .#razer
```

## Git workflow

The intended sequence is:

```text
bootstrap or change
→ inspect
→ validate
→ stage
→ commit
```

Use `git status`, `git status --short`, and `git diff` during review. Staging and committing remain explicit user decisions after inspection. Bootstrap never performs Git mutations.

## Existing users and multiple hosts

The current model selects one primary user for each registered host. Multiple hosts may reuse the same existing `users/<user>/` configuration:

```text
hosts/laptop/   ─┐
                 ├─→ users/alice/
hosts/desktop/  ─┘
```

Host-specific configuration remains under each `hosts/<host>/`; shared user configuration remains in one `users/<user>/` directory. This is not a generalized multiple-users-per-host matrix.

## Templates and bootstrap primitives

Identity-bearing template sources live under:

```text
templates/host/
templates/user/
```

They support exactly:

```text
%HOST%
%USER%
%NAME%
%EMAIL%
```

Placeholders exist only in template sources. Active host/user configuration contains instantiated values. Hardware configuration is generated rather than templated, and shared `modules/` and `config/` content is not duplicated into templates.

The bootstrap scripts have separate responsibilities:

- `bootstrap/render-template` is a strict text renderer for the four supported placeholders. It escapes values for Nix strings and refuses to overwrite output.
- `bootstrap/register-host` is the controlled writer for the deliberately simple explicit registry.
- `bootstrap/apply` performs discovery, preflight, staging, generation, publication, registration, and validation.

Keeping the primitives separate allows rendering and registry mutation to be tested independently from orchestration.

## Package ownership

Package ownership follows configuration scope rather than one mixed package list:

- Minimal tools for every local user: `modules/nixos/base-packages.nix`
- Machine-specific tools: the appropriate `hosts/<host>/machine.nix`
- User applications and utilities: `modules/home/packages.nix`
- Persistent AstroNvim/editor and development dependencies: `modules/home/development.nix`
- Desktop/session system dependencies: the relevant reusable NixOS feature module

## Authentication notes

The current system intentionally combines YubiKey/PAM U2F authentication, `hyprpolkitagent`, and Noctalia Greeter.

After the first successful NixOS activation, the system provides `pam_u2f`, its interactive `pamu2fcfg` enrollment utility, and the system-wide helper `u2f-register`. Enrollment is intentionally not run by bootstrap, Home Manager, `nixos-rebuild`, login, or a systemd service.

Run the helper once as the normal user in an interactive terminal:

```bash
u2f-register
```

It may request the YubiKey PIN and/or a physical touch, then creates the per-user mapping at:

```text
~/.config/Yubico/u2f_keys
```

Do not copy this mapping from another machine. PAM U2F registration uses the current host's relying-party origin, `pam://<hostname>`, so each machine must enroll independently. The ThinkPad and Razer therefore need separate `u2f-register` runs and must not share a `u2f_keys` file.

The Noctalia Greeter setting:

```nix
allow_empty_password = true;
```

is intentional for the current YubiKey greeter authentication flow. Do not remove it casually as generic security cleanup. Never commit or publish U2F mappings, credentials, PINs, or key material.

## State versions

`system.stateVersion` and `home.stateVersion` are lifecycle compatibility values. They control defaults for stateful data and are not declarations of the currently installed package release.

Do not automatically update them to the newest NixOS or Home Manager release. The templates intentionally preserve the repository's current explicit values.

## Troubleshooting

### Repository is not at `/home/<user>/nixos-dotfiles`

Bootstrap refuses because Home Manager's out-of-store dotfile sources would point at a different directory. Move or clone the repository to the required location rather than bypassing the invariant.

### Host already exists

Bootstrap never overwrites an existing host directory or registry entry. Review the existing `hosts/<host>/` and `hosts/registry.nix` state. Adopting a different machine requires a different host name.

### User directory is partial

A repository user requires both:

```text
users/<user>/default.nix
users/<user>/home.nix
```

Bootstrap refuses to guess whether a partial profile should be completed or replaced. Inspect and resolve the directory manually before retrying.

### Write-permission failure

Bootstrap checks effective write/search access for every planned destination before confirmation. Correct the repository ownership or permissions intentionally, then retry. Bootstrap does not create permission-test files in destination directories.

### Hardware generation fails

`nixos-generate-config --show-hardware-config` must succeed as the normal user. Bootstrap does not invoke `sudo` or escalate privileges automatically. Review the command's error and the machine's access restrictions before retrying.

### Flake validation fails after publication

Once publication begins, bootstrap intentionally avoids complex automatic rollback. New host/user/metadata files and the registry entry remain unstaged for inspection and correction. Existing hosts and users are not overwritten.

### Generated host is not tracked by Git

Immediately after bootstrap, paths such as `hosts/<new-host>/` and `users/<new-user>/` may still be untracked. A command such as:

```bash
sudo nixos-rebuild switch --flake .#<host>
```

can then fail with an error similar to `Path 'hosts/<host>' ... is not tracked by Git`. When a flake is interpreted as a Git source, untracked files are not included in that source.

The files do not need to be committed before initial testing. Use an explicit path flake to include the whole working tree:

```bash
sudo nixos-rebuild build --flake path:.#<host>
sudo nixos-rebuild test --flake path:.#<host>
sudo nixos-rebuild switch --flake path:.#<host>
```

After the generated host and user files are tracked by Git, normal commands may use:

```bash
sudo nixos-rebuild switch --flake .#<host>
```

### `~/.config/walls` conflicts with Home Manager

Home Manager expects this path to become an out-of-store link to `~/nixos-dotfiles/config/walls`. Inspect and preserve any files in an existing ordinary directory before performing the first activation. Bootstrap never modifies the destination itself.

## References

This configuration was developed with reference to the following repositories and their approaches to NixOS configuration and system organization:

- https://github.com/dustinlyons
- https://github.com/tonybanters

The final structure and implementation in this repository have been adapted and modified for my own environment and workflow.
