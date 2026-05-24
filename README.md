# Retrowave MVP (Debian-installed Appliance Prototype)

Retrowave is a Debian-based appliance-style runtime that hides Linux and boots into a DOS-oriented launcher for running DOS apps/games through DOSBox engines.

## What this MVP includes

- Debian install script (`scripts/install.sh`) to set up dependencies and files
- Auto-start via systemd (`systemd/retrowave.service`)
- Minimal Xorg flow (`xorg/xinitrc.retrowave`) with optional Openbox
- Python boot/profile menu (`bin/retrowave-menu`)
- Launcher wrapper (`bin/retrowave-launcher`)
- INI profile system (system + user overlays)
- Default profiles:
  - Retrowave Standard (DOSBox-X)
  - Retrowave Gaming (DOSBox-Staging)
  - Safe Mode
- Shared persistent C: at `/var/lib/retrowave/drives/c`
- Basic startup files in C: (`AUTOEXEC.BAT`, `RETROWAVE.TXT`)

## Directory layout

Runtime locations:

- `/var/lib/retrowave/drives/c` - persistent DOS C: directory
- `/var/lib/retrowave/profiles.d` - user profiles
- `/etc/retrowave/profiles.d` - system profiles
- `/etc/retrowave/dosbox` - DOSBox config files
- `/var/lib/retrowave/images` - VM/disk images for Win9x profiles
- `/var/lib/retrowave/installs` - user-provided install media

Repository sources:

- `bin/retrowave-menu` - profile parser/menu/launcher
- `bin/retrowave-launcher` - starts Xorg + Retrowave flow
- `profiles/system/*.ini` - built-in profiles
- `etc/retrowave/dosbox/*.conf` - per-profile emulator tuning

## Install on Debian minimal

```bash
sudo bash scripts/install.sh
sudo systemctl start retrowave.service
```

Optional troubleshooting:

```bash
sudo journalctl -u retrowave.service -f
sudo systemctl status retrowave.service
```

## Profile format (INI)

```ini
[profile]
name=Retrowave Standard
engine=dosbox-x
type=folder
enabled=true
default=true
timeout=5

[storage]
mount_c=/var/lib/retrowave/drives/c

[dosbox]
config=/etc/retrowave/dosbox/dosbox-x-standard.conf
```

For Win95/98 use `type=image` with `hdd_image` and optional `cdrom_image`.

## Add user profile example

Create `/var/lib/retrowave/profiles.d/windows98.ini`:

```ini
[profile]
name=Windows 98
engine=dosbox-x
type=image
enabled=true

[storage]
hdd_image=/var/lib/retrowave/images/win98.img
cdrom_image=/var/lib/retrowave/installs/win98/win98.iso

[dosbox]
config=/etc/retrowave/dosbox/win98.conf
```

## QEMU/VM test notes

- Recommended VM: QEMU/KVM with 2 vCPU, 2 GB RAM, virtio disk.
- Install Debian minimal (no full desktop task).
- Enable serial console in VM for debugging if X fails.
- Snapshot before running installer.
- Validate:
  1. Boot reaches Retrowave menu automatically.
  2. Default profile auto-launches after timeout.
  3. C: files persist after reboot.

## Legal/content boundaries

Retrowave intentionally **does not** ship:

- MS-DOS binaries
- Windows installers or keys
- Games/ROMs/copyrighted assets

Only scaffolding and mount points are provided for user-supplied media.

## TODO (post-MVP)

- Build Debian package and non-interactive installer.
- Create reproducible image-builder pipeline for bootable ISO.
- Add plymouth/splash integration to further hide Linux boot text.
- Add TUI settings/recovery profile with input and display diagnostics.
- Add first-boot wizard for controller/display/audio calibration.
- Harden service (tmpfiles, log rotation, watchdog).
