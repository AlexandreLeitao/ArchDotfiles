#!/usr/bin/env zsh
set -euo pipefail

# ====== CONFIG (edit before running) ======
DISK="/dev/sda"          # target disk (whole device, not a partition)
HOSTNAME="myarch"        # system hostname
LOCALE="en_US.UTF-8"     # locale
TIMEZONE="UTC"           # e.g. Europe/Lisbon
ROOT_PW="Admin!123"      # root password
# =========================================

# Detect mode (UEFI vs BIOS)
if [[ -d /sys/firmware/efi ]]; then
    MODE="UEFI"
    echo ">>> UEFI system detected."
else
    MODE="BIOS"
    echo ">>> BIOS/Legacy system detected."
fi

# Timezone & clock
ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
hwclock --systohc

# Locale
if grep -q "^#${LOCALE} UTF-8" /etc/locale.gen; then
    sed -i "s/^#${LOCALE} UTF-8/${LOCALE} UTF-8/" /etc/locale.gen
elif ! grep -q "^${LOCALE} UTF-8" /etc/locale.gen; then
    echo "${LOCALE} UTF-8" >> /etc/locale.gen
fi
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf

# Hostname & hosts
echo "${HOSTNAME}" > /etc/hostname
cat >/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

# Root password
echo "root:${ROOT_PW}" | chpasswd

# Networking + sudo
pacman -S --noconfirm --needed networkmanager sudo
systemctl enable NetworkManager

# Microcode (recommended)
pacman -S --noconfirm --needed intel-ucode amd-ucode || true

# Bootloader
if [[ "$MODE" == "UEFI" ]]; then
    pacman -S --noconfirm grub efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
    pacman -S --noconfirm grub
    grub-install --target=i386-pc "${DISK}"
fi

grub-mkconfig -o /boot/grub/grub.cfg

echo ">>> setup-post.zsh completed successfully!"