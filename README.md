# NixOS configuration

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
│   └── thinkpad/
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
│   └── mattangi/
│       ├── default.nix
│       └── home.nix
├── flake.nix
└── flake.lock
```

The main layers have deliberately separate responsibilities:

- `hosts/<host>/default.nix` assembles one host. It selects imports and contains instantiated host policy such as the bootloader, hostname, timezone, locale, `system.stateVersion`, and selected NixOS user.
- `hosts/<host>/machine.nix` contains hand-curated model- or machine-specific policy. The current ThinkPad module is specifically for a Lenovo ThinkPad T14s AMD Gen 4 and includes its `nixos-hardware` module and AMD diagnostic tools. Newly bootstrapped hosts start with a minimal empty machine module.
- `hosts/<host>/hardware-configuration.nix` is generated from the machine. It contains detected filesystems, storage, kernel modules, and similar installation-specific hardware state. Keep it separate from curated `machine.nix` policy rather than mixing the two responsibilities.
- `hosts/registry.nix` explicitly associates each host with its primary user and Nix system. Only hosts listed in this registry become `nixosConfigurations.<host>` outputs; host directories are not discovered automatically.
- `modules/nixos/` contains reusable NixOS policy and feature modules, including Nix settings, networking, audio, input methods, fonts, laptop infrastructure, security, desktop/session infrastructure, gaming/graphics, and baseline system packages.
- `users/<user>/default.nix` defines the NixOS account: username, normal-user status, login shell, description, and system groups.
- `users/<user>/home.nix` assembles the user's Home Manager profile, identity, applications, and dotfile mappings.
- `modules/home/` contains reusable Home Manager package policy for user applications and persistent editor/development dependencies.
- `config/` contains live, editable application configuration.

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

Bootstrap adopts an **already running NixOS machine** into this repository. It does not install NixOS from bare metal, partition disks, or replace the current system automatically.

### Prerequisites

Before running bootstrap, the machine should:

- Already run NixOS.
- Use an x86_64 processor.
- Have enough network access to clone the repository and evaluate its flake inputs.
- Be operated as the intended normal user.
- Have the repository cloned to `/home/<user>/nixos-dotfiles`.

Do not run bootstrap as root. It intentionally refuses root execution and never invokes `sudo` internally.

### Clone the repository

Use the required directory name:

```bash
cd "$HOME"
git clone <your-repository-url> nixos-dotfiles
cd nixos-dotfiles
```

Replace `<your-repository-url>` with the actual remote URL.

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
  --host desktop \
  --user mattangi
```

If both `users/mattangi/default.nix` and `users/mattangi/home.nix` already exist, they are reused unchanged. Name and email are neither required nor accepted when reusing an existing user.

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
- `hardware-configuration.nix` is the generated hardware scan for this installation.
- `machine.nix` starts as an empty curated machine module for later review.

Bootstrap also adds an explicit registry entry equivalent to:

```nix
desktop = {
  user = "alice";
  system = "x86_64-linux";
};
```

`bootstrap/register-host` is the controlled writer for that registry entry.

## Review machine configuration before activation

New `hosts/<host>/machine.nix` files are intentionally minimal. Bootstrap does not guess hardware policy from DMI data.

Before activation, review at least:

```text
.bootstrap/<host>/hardware-report.txt
hosts/<host>/hardware-configuration.nix
hosts/<host>/machine.nix
```

Use the report to research and add model-specific settings deliberately. Do not blindly copy `hosts/thinkpad/machine.nix` to another machine: it is specific to the **Lenovo ThinkPad T14s AMD Gen 4**.

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

From the repository root, replace `<host>` and activate manually:

```bash
sudo nixos-rebuild switch \
  --flake 'path:.#<host>' \
  --option experimental-features "nix-command flakes" \
  --no-write-lock-file
```

This does not reboot automatically, but it builds and activates the selected NixOS configuration and updates the system generation.

After the first successful activation, this repository declaratively enables:

```nix
nix.settings.experimental-features = [
  "nix-command"
  "flakes"
];
```

Subsequent flake commands should therefore no longer need the temporary feature option. Do not add imperative settings to `/etc/nix/nix.conf`.

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

### `~/.config/walls` conflicts with Home Manager

Home Manager expects this path to become an out-of-store link to `~/nixos-dotfiles/config/walls`. Inspect and preserve any files in an existing ordinary directory before performing the first activation. Bootstrap never modifies the destination itself.
