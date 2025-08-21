#!/bin/bash
set -euo pipefail

# ---- quick knobs to tweak ----
DISK="/dev/sda"          # target disk for GRUB (the whole disk, not a partition)
HOSTNAME="myarch"        # machine hostname
LOCALE="en_US.UTF-8"     # primary locale
TIMEZONE="UTC"           # e.g. Europe/Lisbon
ROOT_PW="Admin!123"      # change me!
# --------------------------------

# Timezone & clock
ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
hwclock --systohc

# Locale
# Uncomment the locale if present; if not, append and then generate
if grep -q "^#${LOCALE} UTF-8" /etc/locale.gen; then
  sed -i "s/^#${LOCALE} UTF-8/${LOCALE} UTF-8/" /etc/locale.gen
elif ! grep -q "^${LOCALE} UTF-8" /etc/locale.gen; then
  echo "${LOCALE} UTF-8" >> /etc/locale.gen
fi
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf

# Hostname & /etc/hosts
echo "${HOSTNAME}" > /etc/hostname
cat >/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

# Root password
echo "root:${ROOT_PW}" | chpasswd

# Base tools & networking
pacman -S --noconfirm --needed networkmanager sudo vim git

# Enable networking at boot (will start on next boot)
systemctl enable NetworkManager

# GRUB (BIOS/MBR target)
pacman -S --noconfirm --needed grub
grub-install --target=i386-pc "${DISK}"
grub-mkconfig -o /boot/grub/grub.cfg

echo ">>> setup-post.sh completed successfully."
echo "    You can now exit chroot, unmount, and reboot."