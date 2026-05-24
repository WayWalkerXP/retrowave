#!/usr/bin/env bash
set -euo pipefail

# Retrowave MVP installer for Debian-based systems.
# Installs minimal dependencies, creates directories/users, and enables startup service.

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RETROWAVE_USER="retrowave"
RETROWAVE_HOME="/var/lib/retrowave"
RETROWAVE_ETC="/etc/retrowave"

PKGS=(
  xorg
  xinit
  openbox
  dosbox-x
  dosbox-staging
  python3
)

echo "[1/6] Installing packages..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y "${PKGS[@]}"

echo "[2/6] Creating retrowave user and storage layout..."
if ! id -u "$RETROWAVE_USER" >/dev/null 2>&1; then
  useradd -r -m -d "$RETROWAVE_HOME" -s /bin/bash "$RETROWAVE_USER"
fi

install -d -o "$RETROWAVE_USER" -g "$RETROWAVE_USER" -m 0755 \
  "$RETROWAVE_HOME/drives/c" \
  "$RETROWAVE_HOME/profiles.d" \
  "$RETROWAVE_HOME/images" \
  "$RETROWAVE_HOME/installs"

install -d -m 0755 "$RETROWAVE_ETC/profiles.d" "$RETROWAVE_ETC/dosbox"

# Seed basic DOS-like folder layout in persistent C:\ drive.
for d in DOS GAMES UTIL WINDOWS; do
  install -d -o "$RETROWAVE_USER" -g "$RETROWAVE_USER" -m 0755 "$RETROWAVE_HOME/drives/c/$d"
done

echo "[3/6] Installing Retrowave scripts and configs..."
install -d -m 0755 /usr/local/bin
install -m 0755 "$REPO_ROOT/bin/retrowave-launcher" /usr/local/bin/retrowave-launcher
install -m 0755 "$REPO_ROOT/bin/retrowave-menu" /usr/local/bin/retrowave-menu

install -m 0644 "$REPO_ROOT/systemd/retrowave.service" /etc/systemd/system/retrowave.service
install -m 0644 "$REPO_ROOT/xorg/xinitrc.retrowave" "$RETROWAVE_ETC/xinitrc"

install -m 0644 "$REPO_ROOT/profiles/system/retrowave-standard.ini" "$RETROWAVE_ETC/profiles.d/retrowave-standard.ini"
install -m 0644 "$REPO_ROOT/profiles/system/retrowave-gaming.ini" "$RETROWAVE_ETC/profiles.d/retrowave-gaming.ini"
install -m 0644 "$REPO_ROOT/profiles/system/safe-mode.ini" "$RETROWAVE_ETC/profiles.d/safe-mode.ini"

install -m 0644 "$REPO_ROOT/etc/retrowave/dosbox/dosbox-x-standard.conf" "$RETROWAVE_ETC/dosbox/dosbox-x-standard.conf"
install -m 0644 "$REPO_ROOT/etc/retrowave/dosbox/dosbox-staging-gaming.conf" "$RETROWAVE_ETC/dosbox/dosbox-staging-gaming.conf"
install -m 0644 "$REPO_ROOT/etc/retrowave/dosbox/safe-mode.conf" "$RETROWAVE_ETC/dosbox/safe-mode.conf"

install -m 0644 "$REPO_ROOT/share/c_drive/AUTOEXEC.BAT" "$RETROWAVE_HOME/drives/c/AUTOEXEC.BAT"
install -m 0644 "$REPO_ROOT/share/c_drive/RETROWAVE.TXT" "$RETROWAVE_HOME/drives/c/RETROWAVE.TXT"
chown "$RETROWAVE_USER:$RETROWAVE_USER" "$RETROWAVE_HOME/drives/c/AUTOEXEC.BAT" "$RETROWAVE_HOME/drives/c/RETROWAVE.TXT"

echo "[4/6] Ensuring ownership..."
chown -R "$RETROWAVE_USER:$RETROWAVE_USER" "$RETROWAVE_HOME"

echo "[5/6] Enabling service..."
systemctl daemon-reload
systemctl enable retrowave.service

echo "[6/6] Done. Start with: systemctl start retrowave.service"
echo "Logs: journalctl -u retrowave.service -f"
