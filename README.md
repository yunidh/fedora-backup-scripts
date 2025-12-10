# fedora-backup-scripts
Shell scripts to backup Fedora KDE system and restore it on a fresh install.
Stuff included:
 - home dir
 - Flatpaks
 - .RPMs (Redhat package manager) and gpg keys
 - dnf packages 
 
# Steps:
## 1. Edit backup.sh     
 - Change root location, backup location, and username variables 
 - Mount disk beforehand if working from live USB 
 - Run with `bash backup.sh` 
 - Check output___.log file for possible errors (will be generated on same directory as script
 - Make sure everything listed in backup.sh was generated and stored in backup directory 
 
## 2. On new Fedora install, Edit restore.sh
 - Repeat same steps as backup.sh
 - Reboot
 - Run `sudo dnf upgrade --refresh -y` 
 - Reboot again
 - Good to go 
