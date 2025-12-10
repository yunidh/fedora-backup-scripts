#!/usr/bin/env bash
# ============================================================
#  Fedora Full Restore Script (RPM, Repos, Flatpaks, HOME)
#  Use AFTER a clean reinstall of Fedora.
#
#  This restores:
#   - Repos (including 3rd-party: NVIDIA, Chrome, VSCode, COPR)
#   - GPG keys for repos
#   - All RPM packages you had installed
#   - All Flatpaks (Discover installs included)
#   - Your HOME directory (Plasma, Firefox, app data)
#
#  NOTE:
#   Set BACKUP_DIR below to wherever you saved your backup.
#   Example: /mnt/backup or /media/user/usb/backup
# ============================================================

BACKUP_DIR="/"   # <-- CHANGE THIS to your actual backup path
USER_NAME=""   # <-- CHANGE THIS to your username
OLD_UID=""                   # leave blank if you don't want to modify UID

# ============================================================

# Generate unique log filename with format: output<dd-mm-HHMM>.log
LOG_FILE="output$(date +%d-%m-%H%M).log"

# Redirect all output: stdout to log, stderr to both console and log
exec > "$LOG_FILE" 2> >(tee -a "$LOG_FILE" >&2)

echo "=== Restoring repository definitions (yum.repos.d) ==="
sudo rsync -avhP "$BACKUP_DIR/yum.repos.d/" /etc/yum.repos.d/

echo "=== Restoring repo GPG keys ==="
sudo rsync -avhP "$BACKUP_DIR/rpm-gpg/" /etc/pki/rpm-gpg/

echo "=== Ensuring main repos (including RPMFusion) are enabled ==="
sudo dnf config-manager --set-enabled rpmfusion-free || true
sudo dnf config-manager --set-enabled rpmfusion-nonfree || true

if [ -n "$OLD_UID" ]; then
  echo "=== Adjusting user UID to old UID: $OLD_UID ==="
  sudo usermod -u "$OLD_UID" "$USER_NAME"
fi

echo "=== Restoring all RPM packages==="
if [ -f "$BACKUP_DIR/pkglist.txt" ]; then
    sudo dnf install -y $(cat "$BACKUP_DIR/pkglist.txt")
else
    echo "!!! ERROR: pkglist.txt not found in $BACKUP_DIR"
fi

echo "=== Restoring Flatpak apps ==="
if [ -f "$BACKUP_DIR/flatpaklist.txt" ]; then
    flatpak install -y flathub $(cat "$BACKUP_DIR/flatpaklist.txt")
else
    echo "!!! WARNING: flatpaklist.txt not found — skipping Flatpak reinstall."
fi

echo "=== Restoring HOME directory ==="
sudo rsync -avhP "$BACKUP_DIR/home/" /home/"$USER_NAME"/

echo "=== Fixing permissions for HOME directory ==="
sudo chown -R "$USER_NAME":"$USER_NAME" /home/"$USER_NAME"
delete ~/.cache
echo "=== Restore completed ==="
echo "You can reboot now."
echo "Run 'sudo dnf upgrade --refresh -y' after reboot"
