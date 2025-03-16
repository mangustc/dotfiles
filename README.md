# Dotfiles

This dotfiles repository branch is specificaly for:

- **AMD** CPU.
- Mainly **WiFi**.
- Laptops.
- Programming work.
- Partition labels should be as follows: `root` for root part, `boot` for boot part, `swap` for swap part, `home` for home part.
- Obviously me.

Dotfiles structure below is the simplest and most flexible style of managing dotfiles I could find after using linux for many years.

## Basic usage

dotfiles script explanation:

- `sysconfupd` - update system configuration files and save it to `MY_DOTFILES_DIR/root`.
- `dotsln` - link user configuration files to home directory.

other scripts:

- `ebmm` - EFI Boot Manager Manager (EBMM) update EXISTING efi boot entry. Requires boot partition to be labeled `boot`.

There is no help page in these scripts. You should read them before executing.

## Manual stuff

### dotfiles root

You have to manualy copy all the file from `MY_DOTFILES_DIR/root` to respective files in root directory.

### systemd services

You have to manualy enable and start all the systemd services.

### Enabling systemd resolved

```sh
ln -s /usr/lib/systemd/resolv.conf /etc/resolv.conf
```

