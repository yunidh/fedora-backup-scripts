#!/usr/bin/env bash
# ============================================================
#  Fedora Full Backup Script (RPM list, Flatpaks, Repos, HOME)
#  Use BEFORE wiping your system or reinstalling Fedora.
#
#  This backs up:
#    - List of all installed RPMs (including 3rd-party: NVIDIA, Chrome, COPR, etc.)
#    - List of Flatpaks installed by Discover
#    - List of user installed packages (dnf)
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
ROOT_MNT=""               # where your Fedora root fs is mounted
BACKUP_DIR=""         # where your backup disk is mounted
USER_NAME=""   # CHANGE THIS to your actual username
# ============================================================

# Add this after your variables to prevent accidental empty-path runs
if [[ -z "$ROOT_MNT" || -z "$BACKUP_DIR" || -z "$USER_NAME" ]]; then
    echo "ERROR: Please fill in the variables at the top of the script."
    exit 1
fi

# Move the log to the backup folder so it's saved with your data
LOG_FILE="$BACKUP_DIR/backup_$(date +%d-%m-%H%M).log"

# Redirect all output: stdout to log, stderr to both console and log
exec > "$LOG_FILE" 2> >(tee -a "$LOG_FILE" >&2)

echo "=== Creating backup folders ==="
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/yum.repos.d"
mkdir -p "$BACKUP_DIR/rpm-gpg"
mkdir -p "$BACKUP_DIR/home"

echo "=== Backing up essential directories ==="
sudo rsync -avhPAX --exclude='.cache' --exclude='.local/share/Trash' "$ROOT_MNT/home/$USER_NAME/" "$BACKUP_DIR/home/" 2>/dev/null
sudo rsync -avhPAX "$ROOT_MNT/etc/" "$BACKUP_DIR/etc/" 2>/dev/null
sudo rsync -avhPAX "$ROOT_MNT/usr/local/" "$BACKUP_DIR/usr_local/" 2>/dev/null
sudo rsync -avhPAX "$ROOT_MNT/opt/" "$BACKUP_DIR/opt/" 2>/dev/null


echo "=== Backing up list of installed Flatpaks ==="
# Flatpak installation path inside root fs (no chroot needed)
sudo flatpak list --app --columns=application > "$BACKUP_DIR/flatpaklist.txt" 2>/dev/null

echo "=== Backing up list of installed DNF packages (for a live system/useless from USB) ==="
# Using repoquery to get only user-installed packages (excluding dependencies)
sudo dnf repoquery --installed --queryformat "%{name}\n" > "$BACKUP_DIR/dnflist.txt" 2>/dev/null

echo "=== Backing up repository definitions (including 3rd-party repos) ==="
sudo rsync -avhPAX "$ROOT_MNT/etc/yum.repos.d/" "$BACKUP_DIR/yum.repos.d/"

echo "=== Backing up GPG keys for repos ==="
sudo rsync -avhPAX "$ROOT_MNT/etc/pki/rpm-gpg/" "$BACKUP_DIR/rpm-gpg/"



echo "=== BACKUP COMPLETE ==="
echo ""
echo "Your backup now includes:"
echo " - pkglist.txt and dnflist.txt (all RPM/dnf packages)"
echo " - flatpaklist.txt (all Flatpak apps)"
echo " - yum.repos.d/ (all repo definitions)"
echo " - rpm-gpg/ (all repo GPG keys)"
echo " - home/ (your full HOME directory)"
echo ""
echo "This backup is ready for the restore script after your clean reinstall."
