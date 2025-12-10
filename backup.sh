#!/usr/bin/env bash
# ============================================================
#  Fedora Full Backup Script (RPM list, Flatpaks, Repos, HOME)
#  Use BEFORE wiping your system or reinstalling Fedora.
#
#  This backs up:
#    - List of all installed RPMs (including 3rd-party: NVIDIA, Chrome, COPR, etc.)
#    - List of Flatpaks installed by Discover
#    - All repository files in /etc/yum.repos.d
#    - All GPG keys for repos in /etc/pki/rpm-gpg
#    - Full HOME directory (user settings, Firefox, Discord, Plasma configs)
#
#  REQUIREMENTS:
#    - $ROOT_MNT already mounted to your Linux root partition (e.g. /mnt)
#    - $BACKUP_DIR already mounted to your backup location
#
# ============================================================
# CHANGE THESE to match your environment
ROOT="/your/root/location"               # where your Fedora root is stored
BACKUP_DIR="/your/backup/location"          # where your backup should be stored
USER_NAME="<your-username>"   # CHANGE THIS to your actual username

# ============================================================

# Generate unique log filename with format: output<dd-mm-HHMM>.log
LOG_FILE="output$(date +%d-%m-%H%M).log"

# Redirect all output: stdout to log, stderr to both console and log
exec > "$LOG_FILE" 2> >(tee -a "$LOG_FILE" >&2)

echo "=== Creating backup folders ==="
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/yum.repos.d"
mkdir -p "$BACKUP_DIR/rpm-gpg"
mkdir -p "$BACKUP_DIR/home"

echo "=== Backing up HOME directory (Plasma configs, Flatpak data, app settings) ==="
sudo rsync -avhP "$ROOT_MNT/home/$USER_NAME/" "$BACKUP_DIR/home/"

echo "=== Backing up list of installed RPM packages ==="
sudo rpm --root "$ROOT_MNT" -qa --qf "%{NAME}\n" > "$BACKUP_DIR/pkglist.txt"

echo "=== Backing up list of installed Flatpaks ==="
# Flatpak installation path inside root fs (no chroot needed)
flatpak --installation="$ROOT_MNT/var/lib/flatpak" list --app --columns=application > "$BACKUP_DIR/flatpaklist.txt" 2>/dev/null

echo "=== Backing up repository definitions (including 3rd-party repos) ==="
sudo rsync -avhP "$ROOT_MNT/etc/yum.repos.d/" "$BACKUP_DIR/yum.repos.d/"

echo "=== Backing up GPG keys for repos ==="
sudo rsync -avhP "$ROOT_MNT/etc/pki/rpm-gpg/" "$BACKUP_DIR/rpm-gpg/"

echo "=== BACKUP COMPLETE ==="
echo ""
echo "Your backup now includes:"
echo " - pkglist.txt (all RPM packages)"
echo " - flatpaklist.txt (all Flatpak apps)"
echo " - yum.repos.d/ (all repo definitions)"
echo " - rpm-gpg/ (all repo GPG keys)"
echo " - home/ (your full HOME directory)"
echo ""
echo "This backup is ready for the restore script after your clean reinstall."
