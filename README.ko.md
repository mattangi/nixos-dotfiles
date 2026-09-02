# NixOS configuration

[English](README.md)

> `README.md`가 canonical English 문서입니다. `README.ko.md`는 한국어 번역이며, 두 문서의 내용이 다를 경우 번역이 동기화될 때까지 English README를 기준으로 합니다.

이 repository는 host별 설정, NixOS user 계정, Home Manager profile, 편집 가능한 application dotfile, 추가 machine을 도입하기 위한 bootstrap workflow를 포함한 선언형 NixOS system을 관리합니다.

현재 지원하는 platform은 **x86_64-linux의 NixOS**입니다. bootstrap은 ARM이나 다른 architecture를 지원하지 않으며, nix-darwin/macOS도 현재 지원하지 않습니다.

## Repository 구조

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

주요 layer는 의도적으로 서로 다른 책임을 가집니다.

- `hosts/<host>/default.nix`는 하나의 host를 구성합니다. import를 선택하고 bootloader, hostname, timezone, locale, `system.stateVersion`, 선택한 NixOS user 같은 구체화된 host policy를 포함합니다.
- `hosts/<host>/machine.nix`는 의도적으로 직접 관리하는 model 또는 machine별 policy를 포함합니다. 새로 bootstrap한 host는 bootstrap이 이 policy를 추측하지 않기 때문에 최소한의 빈 module로 시작합니다.
- `hosts/<host>/hardware-configuration.nix`는 현재 실제 machine에서 생성됩니다. 감지된 filesystem, storage, kernel module 및 이와 유사한 설치별 상태를 포함합니다. 두 책임을 섞지 말고, 직접 관리하는 `machine.nix` policy와 분리해서 유지하십시오.
- `hosts/registry.nix`는 각 host를 primary user 및 Nix system과 명시적으로 연결합니다. 이 registry에 등록된 host만 `nixosConfigurations.<host>` output이 되며, host directory를 자동으로 검색하지 않습니다.
- `modules/nixos/`는 Nix 설정, networking, audio, input method, font, laptop infrastructure, security, desktop/session infrastructure, gaming/graphics 및 기본 system package를 포함하는 재사용 가능한 NixOS policy와 feature module을 담습니다.
- `users/<user>/default.nix`는 username, normal-user 여부, login shell, description, system group 등 NixOS 계정을 정의합니다.
- `users/<user>/home.nix`는 user의 Home Manager profile, identity, application 및 dotfile mapping을 구성합니다.
- `modules/home/`은 user application 및 지속적으로 필요한 editor/development dependency를 위한 재사용 가능한 Home Manager package policy를 담습니다.
- `config/`는 실제로 사용하며 편집 가능한 application 설정을 담습니다.

현재 추적 중인 실제 host는 다음과 같습니다.

- `thinkpad`: Lenovo ThinkPad T14s AMD Gen 4, primary user는 `mattangi`입니다.
- `razer`: Razer Blade 15 Advanced, model RZ09-0301, primary user는 `kyoon`입니다.

이 관계는 `hosts/registry.nix`에 정의되어 있습니다. 상세 hardware policy는 이 목록이 아니라 각 host의 `machine.nix`에 두어야 합니다.

### 편집 가능한 dotfile

Home Manager는 의도적으로 `config.lib.file.mkOutOfStoreSymlink`를 사용해 application 설정을 노출합니다. source는 다음 위치에서 계속 편집할 수 있습니다.

```text
~/nixos-dotfiles/config
```

설정은 변경할 수 없는 Nix store 관리 file로 복사되지 않습니다. 따라서 repository를 source of truth로 유지하면서 application과 plugin manager가 설정을 업데이트할 수 있습니다.

## 필수 repository 위치

repository는 반드시 다음 위치에 있어야 합니다.

```text
/home/<user>/nixos-dotfiles
```

예:

```text
/home/alice/nixos-dotfiles
```

Home Manager profile이 편집 가능한 dotfile root를 다음과 같이 결정하므로 이 위치가 필수입니다.

```nix
${config.home.homeDirectory}/nixos-dotfiles/config
```

`bootstrap/apply`는 이 불변 조건을 강제합니다. repository를 임의 위치에 clone한 뒤 오류를 우회하지 마십시오. 그렇게 하면 out-of-store link가 잘못된 directory를 가리킵니다.

## NixOS machine 도입

Bootstrap은 **이미 설치되어 현재 boot된 NixOS system**을 이 repository에 도입하는 workflow입니다. 해당 system의 repository 설정을 만들고 검증합니다. bare-metal installer가 아니며 disk partition, NixOS 설치 또는 실행 중인 설정의 자동 교체를 수행하지 않습니다.

### 사전 요구 사항

bootstrap 직전 machine은 반드시 다음 상태여야 합니다.

- NixOS가 설치되어 현재 실행 중이어야 합니다.
- `x86_64-linux` system이어야 합니다.
- 이후 수동 activation에 사용할 `sudo` 권한이 있는 일반 non-root user 계정이 있어야 합니다.
- repository clone 및 flake input 평가를 위한 network가 작동해야 합니다.
- `nix`, `nixos-generate-config`, `nixos-rebuild`를 포함한 표준 NixOS tool이 있어야 합니다.
- 이 repository를 clone하는 데 필요한 `git`이 있어야 합니다.
- bootstrap hardware report에 쓰이는 `lspci`를 제공하는 `pciutils`가 있어야 합니다.

첫 activation 전에 생성된 `hosts/<host>/machine.nix`를 검토하고 관리하려면 `vim` 또는 다른 text editor를 강력히 권장합니다. `wget`과 `unzip`은 편의 또는 복구에 유용하지만 `bootstrap/apply`가 의존하지는 않습니다.

bootstrap을 root로 실행하지 마십시오. root 실행을 의도적으로 거부하며 내부에서 `sudo`를 호출하지 않습니다.

최종 repository 설정은 flake를 선언적으로 활성화합니다. bootstrap 전에 flake와 `nix-command`가 전역으로 활성화되어 있을 필요는 없습니다. script는 최초 검증에 필요한 임시 experimental-feature 설정을 직접 제공합니다.

### Repository clone

최소 구성의 새 NixOS 설치에서는 먼저 `/etc/nixos/configuration.nix`를 수정하지 않고도 임시로 bootstrap tool을 사용할 수 있습니다.

```bash
nix-shell -p git pciutils vim
```

해당 package shell에서 필수 위치에 clone합니다.

```bash
cd ~
git clone https://github.com/mattangi/nixos-dotfiles.git
cd ~/nixos-dotfiles
```

첫 activation이 성공하면 repository가 `modules/nixos/base-packages.nix`를 통해 일반적인 기본 tool을 선언적으로 설치합니다.

### Bootstrap 실행

가장 간단한 interactive 실행 방법은 다음과 같습니다.

```bash
./bootstrap/apply
```

변경 없이 지원 option을 표시하려면 다음을 실행합니다.

```bash
./bootstrap/apply --help
```

생략하면 bootstrap이 다음 값을 탐지하거나 제안합니다.

- 현재 static hostname
- 현재 user
- machine architecture

새 repository user를 생성해야 할 때 누락된 identity 정보를 묻습니다.

기존 repository user로 다른 host를 도입하려면 다음과 같이 실행합니다.

```bash
./bootstrap/apply \
  --host razer \
  --user kyoon
```

이 명령은 성공적으로 검증한 Razer 도입에 사용되었습니다. `users/kyoon/`처럼 기존 user의 두 file이 완전하면 bootstrap은 변경 없이 재사용합니다. 기존 user를 재사용할 때 name과 email은 필요하지 않으며 제공할 수도 없습니다.

새 user를 생성하려면 다음과 같이 실행합니다.

```bash
./bootstrap/apply \
  --host desktop \
  --user alice \
  --name "Alice Example" \
  --email "alice@example.com"
```

다음 두 file을 생성합니다.

```text
users/alice/default.nix
users/alice/home.nix
```

선택한 user는 bootstrap을 현재 실행 중인 일반 user와 반드시 같아야 합니다.

non-interactive 실행에는 다음을 추가합니다.

```text
--yes
```

`--yes`는 마지막 확인만 건너뜁니다. overwrite 강제, 검증 또는 architecture check 우회, 기존 host/user 교체, conflict check 완화를 수행하지 않습니다.

## Bootstrap이 하는 일

`bootstrap/apply`는 다음 단계를 순서대로 수행합니다.

1. Repository layout과 필수 tool을 검증합니다.
2. Host, 현재 user, x86_64 architecture를 탐지하고 검증합니다.
3. Repository 위치 불변 조건을 강제합니다.
4. Host, user, registry, metadata, wallpaper path conflict를 검사합니다.
5. 이번 실행이 변경할 모든 대상의 실질적인 write 권한을 검사합니다.
6. 계획된 host, user, path, 고정 template 기본값을 표시한 후 확인을 요청합니다.
7. Host template을 임시 staging 영역에 render합니다.
8. User가 새 user일 때만 두 user template을 render합니다.
9. 일반적이며 의도적으로 비어 있는 `machine.nix`를 생성합니다.
10. 다음 명령으로 hardware configuration을 생성합니다.

    ```bash
    nixos-generate-config --show-hardware-config
    ```

11. 안전한 local machine metadata를 수집합니다.
12. Local `config/walls/` source directory가 존재하도록 합니다.
13. 기존 path를 덮어쓰지 않고 새 host/user/metadata file을 게시합니다.
14. `bootstrap/register-host`를 통해 host를 등록합니다.
15. Working tree flake를 검사하고 새 host의 system derivation을 평가합니다.
16. 종료합니다.

**Bootstrap은 system을 activation하지 않습니다.**

Razer host는 실제 hardware에서 repository clone, bootstrap 생성, hardware 생성, `machine.nix` 준비, flake 검증, build, `nixos-rebuild test`, `nixos-rebuild switch`까지 검증되었습니다.

## Bootstrap이 하지 않는 일

Bootstrap은 다음 작업을 하지 않습니다.

- `nixos-rebuild switch` 또는 `nixos-rebuild boot` 실행
- `home-manager switch` 실행
- Service 또는 desktop session 재시작이나 reboot
- `/etc/nix/nix.conf` 수정
- 빈 disk에 NixOS 설치 또는 storage partition
- `nixos-hardware` machine profile 자동 선택
- CPU/GPU tuning 또는 machine별 quirk 자동 설정
- YubiKey 등록 또는 PAM/authentication 상태 변경
- 외부 AI service 호출
- Secret, key, password 또는 token bootstrap
- Git 변경 stage, commit 또는 push
- Git branch 생성 또는 전환
- 기존 host 또는 user overwrite
- 게시 이후 자동 rollback

## 생성되는 host layout

`desktop`이라는 host를 도입하면 다음이 생성됩니다.

```text
hosts/desktop/
├── default.nix
├── hardware-configuration.nix
└── machine.nix
```

- `default.nix`는 shared module, 선택한 user, hostname, project 기본값을 구성합니다.
- `hardware-configuration.nix`는 `nixos-generate-config --show-hardware-config`를 통해 현재 설치에서 생성됩니다. 감지된 설치 및 hardware 상태를 나타내므로 직접 관리하는 model tuning을 넣지 마십시오.
- `machine.nix`는 최소한의 빈 module로 시작하며 의도적인 model policy를 두는 곳입니다.

Bootstrap은 다음과 같은 명시적인 registry entry도 추가합니다.

```nix
desktop = {
  user = "alice";
  system = "x86_64-linux";
};
```

`bootstrap/register-host`가 이 registry entry를 제어하여 작성합니다.

## 첫 activation 전 `machine.nix` 준비

다음 명령 실행 후:

```bash
./bootstrap/apply --host <host> --user <user>
```

bootstrap은 의도적으로 최소한의 `hosts/<host>/machine.nix`를 생성합니다. GPU driver, hardware profile, PRIME topology, CPU tuning 또는 model별 quirk를 추측해서는 안 됩니다.

첫 `nixos-rebuild switch` 전에 다음을 검토하십시오.

```text
.bootstrap/<host>/hardware-report.txt
hosts/<host>/hardware-configuration.nix
```

실제 hardware를 직접 확인할 수도 있습니다.

```bash
lspci -nn
lscpu
```

이 정보를 사용해 다음 중 어떤 경우인지 판단합니다.

1. **이미 검증된 machine configuration이 있습니다.** 첫 build 전에 bootstrap이 만든 빈 `machine.nix`를 검증된 curated file로 교체하십시오. 다른 model의 policy를 무작정 복사하지 마십시오.
2. **Machine이 새롭거나 알려지지 않았습니다.** 생성된 report, 생성된 hardware configuration, 실제 hardware 정보로 적절한 설정을 조사하십시오. `machine.nix`에는 검증된 `nixos-hardware` import, CPU별 configuration, GPU driver policy, NVIDIA PRIME configuration, Intel 또는 AMD graphics policy, power 또는 thermal 설정, model별 kernel parameter, firmware 또는 device quirk, host별 diagnostic package 등이 들어갈 수 있습니다. ChatGPT 또는 Codex가 hardware 정보를 분석하고 module을 제안하도록 도움받을 수 있지만 user가 결과를 반드시 검토해야 하며, bootstrap은 외부 AI service를 절대 자동 호출하지 않습니다.
3. **Machine별 configuration이 필요하지 않습니다.** 최소한으로 생성된 `machine.nix`를 비워 두어도 됩니다.

책임을 다음과 같이 분리하여 유지하십시오.

```text
hardware-configuration.nix = generated detected installation/hardware state
machine.nix                = intentionally maintained model-specific policy
```

직접 관리하는 machine policy를 `hardware-configuration.nix`에 합치지 마십시오. 실제 사례로 Razer host의 Intel/NVIDIA PRIME policy는 첫 activation 전에 `hosts/razer/machine.nix`에 준비했습니다.

## Local bootstrap metadata

Bootstrap은 local diagnostic 상태를 다음 위치에 보관합니다.

```text
.bootstrap/<host>/
├── hardware-configuration.nix.tmp
├── hardware-report.txt
└── inputs.txt
```

- `hardware-configuration.nix.tmp`는 게시에 사용한 정확한 generated hardware configuration입니다.
- `hardware-report.txt`는 architecture, hostname, 선택된 DMI model field, CPU 세부 정보, PCI device를 포함합니다.
- `inputs.txt`는 host/user/system input과 template 기본값을 기록합니다.

`.bootstrap/`은 의도적으로 Git에서 ignore됩니다. 생성된 hardware configuration의 hardware 세부 정보와 filesystem UUID를 포함할 수 있으므로 portable shared configuration source나 secret storage가 아닌 local diagnostic 상태로 취급하십시오.

Bootstrap은 의도적으로 serial number, product UUID, YubiKey/U2F data, credential, SSH key, password 및 token을 수집하지 않습니다.

## Wallpaper

편집 가능한 wallpaper source는 다음과 같습니다.

```text
config/walls/
```

Home Manager는 out-of-store link를 통해 이 source를 다음 위치에 노출합니다.

```text
~/.config/walls
```

Noctalia도 `~/.config/walls`를 사용합니다. Source directory는 의도적으로 Git에서 ignore됩니다. Bootstrap은 `config/walls/`가 없으면 빈 directory를 생성하지만 wallpaper file을 추가하거나 변경하지 않습니다.

첫 Home Manager activation 전에 `~/.config/walls`가 일반 directory로 이미 존재하면 먼저 내용을 확인하고 보존하십시오. Home Manager는 이 path를 link로 관리하려고 합니다. file을 어떻게 유지할지 결정하지 않은 채 기존 directory를 삭제하거나 교체하지 마십시오.

## Activation 전 변경 사항 검토

Bootstrap은 모든 변경을 unstaged 상태로 둡니다. 다음 명령으로 시작하십시오.

```bash
git status
git status --short
git diff
```

일반적인 `git diff`는 새 untracked file의 내용을 표시하지 않습니다. 새로 생성된 다음 file도 직접 검토하십시오.

- `hosts/<host>/default.nix`
- `hosts/<host>/hardware-configuration.nix`
- `hosts/<host>/machine.nix`
- 새 user를 생성한 경우 `users/<user>/` 아래의 file
- `hosts/registry.nix`

bootstrap이 완료되었다는 이유만으로 stage하거나 commit하지 마십시오. 먼저 검토하고 검증하십시오.

## 수동 검증 반복

생성된 file이 아직 untracked일 수 있으므로 working tree path 형식을 사용합니다.

```bash
nix \
  --option experimental-features "nix-command flakes" \
  flake check 'path:.' \
  --no-build \
  --no-write-lock-file
```

그런 다음 `<host>`를 선택한 host로 바꾸어 평가합니다.

```bash
nix \
  --option experimental-features "nix-command flakes" \
  eval \
  "path:.#nixosConfigurations.<host>.config.system.build.toplevel.drvPath" \
  --raw \
  --no-write-lock-file
```

`path:.`는 untracked working-tree file을 포함합니다. 일반 Git-backed flake reference에서는 이 file들이 제외될 수 있습니다.

현재 실행 중인 NixOS generation이 아직 이 repository의 선언적 Nix 설정을 activation하지 않았다면 임시 experimental-feature option이 필요합니다. 우회 방법으로 `/etc/nix/nix.conf`를 수정하지 마십시오.

## 첫 activation

activation 전에 다음을 수행하십시오.

1. 생성된 모든 file을 확인합니다.
2. Machine에 model별 policy가 필요하면 `hosts/<host>/machine.nix`를 관리합니다.
3. 기존 `~/.config/walls` directory가 있다면 이해하고 보존합니다.
4. 위의 flake check와 derivation 평가를 반복합니다.

> **경고:** 다음 명령은 실행 중인 system을 실제로 변경하는 지점입니다. Bootstrap은 절대 이 명령을 실행하지 않습니다.

bootstrap 직후 생성된 host file과 경우에 따라 user file은 untracked 상태입니다. Repository root에서 명시적인 path flake를 사용하여 working-tree file을 포함하고, build, test activation, persistent activation을 신중하게 차례로 진행하십시오.

```bash
sudo nixos-rebuild build --flake 'path:.#<host>' \
  --option experimental-features "nix-command flakes"
sudo nixos-rebuild test --flake 'path:.#<host>' \
  --option experimental-features "nix-command flakes"
sudo nixos-rebuild switch --flake 'path:.#<host>' \
  --option experimental-features "nix-command flakes"
```

`build`는 activation하지 않고 system을 생성합니다. `test`는 boot 기본값으로 만들지 않고 activation합니다. `switch`는 activation하고 기본 system generation을 업데이트합니다. 어느 명령도 자동으로 reboot하지 않습니다.

첫 activation 성공 후 이 repository는 다음을 선언적으로 활성화합니다.

```nix
nix.settings.experimental-features = [
  "nix-command"
  "flakes"
];
```

이후 flake 명령에는 임시 feature option이 더 이상 필요하지 않습니다. `/etc/nix/nix.conf`에 명령형 설정을 추가하지 마십시오.

첫 activation 성공 후 [Authentication 참고 사항](#authentication-참고-사항)에 설명된 YubiKey enrollment를 수행하십시오.

검증된 도입 순서는 다음과 같습니다.

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

## 일반 update 및 rebuild workflow

이미 구성된 machine에서 다른 곳의 변경을 pull하기 전에 local 작업을 검토하십시오.

```bash
cd ~/nixos-dotfiles
git status
git pull --ff-only origin main
```

Local uncommitted 변경이 들어오는 작업과 겹칠 수 있으므로 pull 전에 확인하십시오.

고정된 flake input을 업데이트하고 결과를 검증하려면 다음을 실행합니다.

```bash
nix flake update
nix flake check
```

`nix flake update`는 `flake.lock`을 변경합니다. 변경을 검토하고 성공적으로 test한 후에만 의도적으로 commit하십시오.

현재 host의 configuration을 activation합니다.

```bash
sudo nixos-rebuild switch --flake .#thinkpad
```

또는:

```bash
sudo nixos-rebuild switch --flake .#razer
```

## Git workflow

의도한 순서는 다음과 같습니다.

```text
bootstrap or change
→ inspect
→ validate
→ stage
→ commit
```

검토 중에는 `git status`, `git status --short`, `git diff`를 사용하십시오. Stage와 commit은 검토 후 user가 명시적으로 결정합니다. Bootstrap은 Git 변경을 절대 수행하지 않습니다.

## 기존 user와 여러 host

현재 model은 등록된 각 host에 하나의 primary user를 선택합니다. 여러 host에서 동일한 기존 `users/<user>/` configuration을 재사용할 수 있습니다.

```text
hosts/laptop/   ─┐
                 ├─→ users/alice/
hosts/desktop/  ─┘
```

Host별 configuration은 각 `hosts/<host>/` 아래에 두고, shared user configuration은 하나의 `users/<user>/` directory에 둡니다. 이는 일반화된 host당 다중 user matrix가 아닙니다.

## Template과 bootstrap primitive

Identity를 포함하는 template source는 다음 위치에 있습니다.

```text
templates/host/
templates/user/
```

정확히 다음 항목을 지원합니다.

```text
%HOST%
%USER%
%NAME%
%EMAIL%
```

Placeholder는 template source에만 존재합니다. 실제 host/user configuration에는 구체화된 값이 들어 있습니다. Hardware configuration은 template이 아니라 생성되는 것이며, shared `modules/` 및 `config/` 내용은 template에 복제되지 않습니다.

Bootstrap script의 책임은 다음과 같이 분리됩니다.

- `bootstrap/render-template`은 지원하는 네 placeholder의 엄격한 text renderer입니다. Nix string에 맞게 값을 escape하며 output을 overwrite하지 않습니다.
- `bootstrap/register-host`는 의도적으로 단순하고 명시적인 registry를 제어하여 작성합니다.
- `bootstrap/apply`는 discovery, preflight, staging, generation, publication, registration 및 validation을 수행합니다.

Primitive를 분리하면 orchestration과 독립적으로 rendering 및 registry 변경을 test할 수 있습니다.

## Package 소유권

Package 소유권은 하나의 혼합 package list가 아니라 configuration scope를 따릅니다.

- 모든 local user를 위한 최소 tool: `modules/nixos/base-packages.nix`
- Machine별 tool: 해당 `hosts/<host>/machine.nix`
- User application 및 utility: `modules/home/packages.nix`
- 지속적인 AstroNvim/editor 및 development dependency: `modules/home/development.nix`
- Desktop/session system dependency: 관련 재사용 가능 NixOS feature module

## Authentication 참고 사항

현재 system은 YubiKey/PAM U2F authentication, `hyprpolkitagent`, Noctalia Greeter를 의도적으로 함께 사용합니다.

첫 NixOS activation 성공 후 system은 `pam_u2f`, interactive `pamu2fcfg` enrollment utility, system-wide helper `u2f-register`를 제공합니다. Enrollment는 bootstrap, Home Manager, `nixos-rebuild`, login 또는 systemd service에서 의도적으로 실행되지 않습니다.

일반 user로 interactive terminal에서 helper를 한 번 실행하십시오.

```bash
u2f-register
```

YubiKey PIN 및/또는 실제 touch를 요청할 수 있으며, 다음 위치에 user별 mapping을 생성합니다.

```text
~/.config/Yubico/u2f_keys
```

이 mapping을 다른 machine에서 복사하지 마십시오. PAM U2F 등록은 현재 host의 relying-party origin인 `pam://<hostname>`을 사용하므로 각 machine에서 독립적으로 enrollment해야 합니다. 따라서 ThinkPad와 Razer에서 각각 `u2f-register`를 실행해야 하며 하나의 `u2f_keys` file을 공유해서는 안 됩니다.

Noctalia Greeter 설정:

```nix
allow_empty_password = true;
```

이 설정은 현재 YubiKey greeter authentication workflow를 위해 의도된 것입니다. 일반적인 security cleanup이라는 이유로 함부로 제거하지 마십시오. U2F mapping, credential, PIN 또는 key material을 절대 commit하거나 publish하지 마십시오.

## State version

`system.stateVersion`과 `home.stateVersion`은 lifecycle compatibility 값입니다. Stateful data의 기본값을 제어하며 현재 설치된 package release를 선언하는 값이 아닙니다.

최신 NixOS 또는 Home Manager release에 맞춰 자동으로 업데이트하지 마십시오. Template은 repository의 현재 명시적 값을 의도적으로 유지합니다.

## Troubleshooting

### Repository가 `/home/<user>/nixos-dotfiles`에 없음

Home Manager의 out-of-store dotfile source가 다른 directory를 가리키게 되므로 bootstrap이 거부합니다. 불변 조건을 우회하지 말고 repository를 필수 위치로 이동하거나 그곳에 clone하십시오.

### Host가 이미 존재함

Bootstrap은 기존 host directory나 registry entry를 절대 overwrite하지 않습니다. 기존 `hosts/<host>/`와 `hosts/registry.nix` 상태를 검토하십시오. 다른 machine을 도입하려면 다른 host name이 필요합니다.

### User directory가 불완전함

Repository user에는 다음 두 file이 모두 필요합니다.

```text
users/<user>/default.nix
users/<user>/home.nix
```

Bootstrap은 불완전한 profile을 완성할지 교체할지 추측하지 않습니다. 다시 시도하기 전에 directory를 직접 검토하고 해결하십시오.

### Write permission 오류

Bootstrap은 확인 전에 변경 대상 전체의 실질적인 write/search 권한을 검사합니다. Repository ownership 또는 permission을 의도적으로 수정한 뒤 다시 시도하십시오. Bootstrap은 대상 directory에 permission test file을 만들지 않습니다.

### Hardware 생성 실패

`nixos-generate-config --show-hardware-config`는 일반 user로 성공해야 합니다. Bootstrap은 `sudo`를 호출하거나 자동으로 권한을 높이지 않습니다. 명령 오류와 machine의 접근 제한을 확인한 후 다시 시도하십시오.

### 게시 후 flake 검증 실패

게시가 시작된 뒤 bootstrap은 의도적으로 복잡한 자동 rollback을 피합니다. 새 host/user/metadata file과 registry entry는 검토 및 수정을 위해 unstaged 상태로 남습니다. 기존 host와 user는 overwrite되지 않습니다.

### 생성된 host가 Git에서 추적되지 않음

bootstrap 직후 `hosts/<new-host>/`와 `users/<new-user>/` 같은 path는 아직 untracked일 수 있습니다. 다음과 같은 명령은:

```bash
sudo nixos-rebuild switch --flake .#<host>
```

`Path 'hosts/<host>' ... is not tracked by Git`과 유사한 오류로 실패할 수 있습니다. Flake를 Git source로 해석하면 untracked file은 flake source에 포함되지 않기 때문입니다.

초기 test 전에 file을 commit할 필요는 없습니다. 전체 working tree를 포함하도록 명시적인 path flake를 사용하십시오.

```bash
sudo nixos-rebuild build --flake path:.#<host>
sudo nixos-rebuild test --flake path:.#<host>
sudo nixos-rebuild switch --flake path:.#<host>
```

생성된 host 및 user file이 Git에서 추적된 이후에는 일반 명령을 사용할 수 있습니다.

```bash
sudo nixos-rebuild switch --flake .#<host>
```

### `~/.config/walls`가 Home Manager와 충돌함

Home Manager는 이 path가 `~/nixos-dotfiles/config/walls`를 가리키는 out-of-store link가 될 것으로 예상합니다. 첫 activation 전에 기존 일반 directory의 file을 확인하고 보존하십시오. Bootstrap은 destination 자체를 절대 수정하지 않습니다.
