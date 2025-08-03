# dotfiles

## why?

My goal is:

- to use the same dotfiles repository for multiple arch linux devices such as my laptop and legion go.
- store and configure system configuration as conventional methods do not allow editing system configuration.

## how?

- separate configuration to different modules.
- each module can accept arguments to specify configuration individually for each host.
- each module has an install script that can be written in whatever way you want.
- provide simple functions that make the proccess of applying a configuration easier.

## prerequisites

- RUN ONLY AS USER, ROOT IS NOT TESTED. reason: this configuration uses sudo to escalate privileges if needed.
- Arch linux.
- paru installed.
- connected to network.
- partition table as follows: root partition labeled arch-root, boot partition labeled arch-boot.

## usage

run `configuration-HOST.sh`.

Afterwards, if archscripts module is installed you can use archupd and archconf.

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
DOTFILES_HOST="your-host-name"
DOTFILES_DIR="your-dotfiles-dir"
cd "$(DOTFILES_DIR)"
source ./base.sh
```

### base.sh

This file contains bash functions that simplify config creation.

### modules

each module has install scripts which can be anything you want. Also it is possible to define a package list in `packages` file.
