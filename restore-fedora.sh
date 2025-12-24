#!/usr/bin/env bash
# ============================================================
#  Fedora Full Restore Script
#
#  NOTE:
#   Set BACKUP_DIR below to wherever you saved your backup.
#   Example: /mnt/backup or /media/user/usb/backup
# ============================================================

BACKUP_DIR=""   # <-- CHANGE THIS to your actual backup path
USER_NAME=""   # <-- CHANGE THIS to your username
OLD_UID=""                   # leave blank if you don't want to modify UID

# ============================================================

# Add this after your variables to prevent accidental empty-path runs
if [[ -z "$ROOT_MNT" || -z "$BACKUP_DIR" || -z "$USER_NAME" ]]; then
    echo "ERROR: Please fill in the variables at the top of the script."
    exit 1
fi

# Move the log to the backup folder so it's saved with your data
LOG_FILE="$BACKUP_DIR/backup_$(date +%d-%m-%H%M).log"


echo "=== Restoring repository definitions (yum.repos.d) ==="
sudo rsync -avhPAX "$BACKUP_DIR/yum.repos.d/" /etc/yum.repos.d/

echo "=== Restoring repo GPG keys ==="
sudo rsync -avhPAX "$BACKUP_DIR/rpm-gpg/" /etc/pki/rpm-gpg/

echo "=== Ensuring main repos (including RPMFusion) are enabled ==="
sudo dnf config-manager --set-enabled rpmfusion-free || true
sudo dnf config-manager --set-enabled rpmfusion-nonfree || true

if [ -n "$OLD_UID" ]; then
  echo "=== Adjusting user UID to old UID: $OLD_UID ==="
  sudo usermod -u "$OLD_UID" "$USER_NAME"
fi

echo "=== Restoring DNF packages ==="
if [ -f "$BACKUP_DIR/dnflist.txt" ]; then
    echo "=== Restoring DNF packages ==="
    sudo dnf install -y --skip-broken $(cat "$BACKUP_DIR/dnflist.txt")
else
    echo "!!! ERROR: dnflist.txt not found in $BACKUP_DIR"
fi

echo "=== Restoring Flatpak apps ==="
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
if [ -f "$BACKUP_DIR/flatpaklist.txt" ]; then
    flatpak install -y flathub $(cat "$BACKUP_DIR/flatpaklist.txt")
else
    echo "!!! WARNING: flatpaklist.txt not found — skipping Flatpak reinstall."
fi

# --- Directory Restoration (Output to Terminal) ---
echo "=== Restoring Home and System Directories ==="
sudo rsync -avhPAX "$BACKUP_DIR/home/" /home/"$USER_NAME"/
sudo rsync -avhPAX "$BACKUP_DIR/usr_local/" /usr/local/
sudo rsync -avhPAX "$BACKUP_DIR/opt/" /opt/

# --- THE DRY RUN (Output ONLY to Log File) ---
echo "=== Running Dry-Run for /etc (CHECK $LOG_FILE) ==="
#What to look for in your log:

#    >f.c......: The file exists in both places, but the content (checksum) is different. These are your customized files.

#    >f++++++++: This file exists in your backup but is missing on your new system.

#    >f..t......: Only the timestamp is different (usually safe to ignore).
###IMPORTANT: grep ">f.c" output-date.log, to find which files need changing in etc
sudo rsync -avhPAXni "$BACKUP_DIR/etc/" /etc/ > "$LOG_FILE" 2>&1


echo "=== Cleaning Cache ==="
rm -rf /home/"$USER_NAME"/.cache/*

echo "=== Relabeling SELinux Labels (Essential for Fedora) ==="
sudo restorecon -Rv /home/"$USER_NAME"
sudo restorecon -Rv /etc
sudo restorecon -Rv /usr/local
sudo restorecon -Rv /opt

echo "=== RESTORE COMPLETE ==="
echo "Check $LOG_FILE for modified /etc files."
echo "Suggested check: grep '>f.c' $LOG_FILE"

echo "You can reboot after etc check"
echo "Run 'sudo dnf upgrade --refresh -y' after reboot"
