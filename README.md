# dotfiles

My collection of installer scripts with adjacent pacman/AUR package list for Arch Linux. Aside from that shell functions are provided to make configuration simpler.

## prerequisites

- Arch linux.
- paru installed.
- internet connection.
- partition table as follows: root partition labeled `arch-root`, boot partition labeled `arch-boot`.

## usage

run `configuration-HOST.sh`.

Afterwards, if archscripts module is installed you can use `archupd` and `archconf`.

## structure

```
- modules/
  - some_module/
    - install (any executable, mainly shell scripts)
    - packages (paru compatible package list)
  - ...
- base.sh
- configuration-HOST.sh
- packages-HOST
```

### configuration-HOST.sh

Each configuration should start as follows:

```sh
export DOTFILES_HOST="your-host-name"
export DOTFILES_DIR="your-dotfiles-dir"
cd "$(DOTFILES_DIR)"
source ./base.sh
config base
```

### base.sh

This file contains shell functions that simplify config creation.

### modules

Each module has an `install` script which can be anything you want. Also it is possible to define a package list in `packages` file.

## quirks and fixes

## Steam client

Disable `Shader Pre-Caching` in Settings-Downloads. Modern PCs should be OK without without this feature. Also you can increase shader cache size:

```sh
# AMD GPU
export AMD_VULKAN_ICD=RADV
export MESA_SHADER_CACHE_MAX_SIZE=12G

# NVIDIA GPU
export __GL_SHADER_DISK_CACHE_SIZE=12000000000
```

### steam-session

First, try launching steam from a desktop environment, avoiding steam-session. Afterwards, when all steam files are downloaded try launching gamescope steam-session.

If color management does not work with both gamepad and mouse input or touching gamepad disables it, you may enable `Developer Mode` in steam settings and then enabling `Force composite`.
