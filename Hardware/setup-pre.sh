#!/bin/bash
set -euo pipefail

# === CONFIG (adjust as needed) ===
DISK="/dev/sda"          # e.g. /dev/nvme0n1 on NVMe
SWAP_MIB="4096"          # Swap size in MiB (numeric only)
HOSTNAME="myarch"
LOCALE="en_US.UTF-8"
TIMEZONE="UTC"
ROOT_PW="Admin!123"
# ================================

echo ">>> Checking firmware type..."
if [ -d /sys/firmware/efi ]; then
  echo "UEFI system detected."
  MODE="UEFI"
else
  echo "BIOS/Legacy system detected."
  MODE="BIOS"
fi

echo ">>> Wiping old signatures on $DISK"
wipefs -a "$DISK"

# --- Partitioning ---
if [ "$MODE" == "UEFI" ]; then
  echo ">>> Creating GPT layout (ESP + swap + root)"
  sfdisk "$DISK" <<EOF
label: gpt
device: $DISK
unit: MiB

${DISK}1 : size=512,  type=EFI System
${DISK}2 : size=${SWAP_MIB}, type=Linux swap
${DISK}3 :               type=Linux filesystem
EOF

  mkfs.fat -F32 "${DISK}1"
  mkswap "${DISK}2"
  mkfs.ext4 "${DISK}3"

  mount "${DISK}3" /mnt
  mkdir -p /mnt/boot
  mount "${DISK}1" /mnt/boot
  swapon "${DISK}2"

else
  echo ">>> Creating DOS/MBR layout (swap + root)"
  sfdisk "$DISK" <<EOF
label: dos
device: $DISK
unit: MiB

${DISK}1 : size=${SWAP_MIB}, type=82
${DISK}2 :               type=83
EOF

  mkswap "${DISK}1"
  swapon "${DISK}1"
  mkfs.ext4 "${DISK}2"

  mount "${DISK}2" /mnt
fi

# --- Install base system ---
pacstrap /mnt base linux linux-firmware vim git

# --- Generate fstab ---
genfstab -U /mnt >> /mnt/etc/fstab

# --- Copy post-install script ---
cat > /mnt/setup-post.sh <<"EOS"
#!/bin/bash
set -euo pipefail

DISK="__DISK__"
HOSTNAME="__HOSTNAME__"
LOCALE="__LOCALE__"
TIMEZONE="__TIMEZONE__"
ROOT_PW="__ROOTPW__"
MODE="__MODE__"

# Timezone & clock
ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
hwclock --systohc

# Locale
sed -i "s/^#${LOCALE} UTF-8/${LOCALE} UTF-8/" /etc/locale.gen || echo "${LOCALE} UTF-8" >> /etc/locale.gen
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

# Microcode (recommended; harmless to install both)
pacman -S --noconfirm --needed intel-ucode amd-ucode || true

# Bootloader
if [ "$MODE" == "UEFI" ]; then
  pacman -S --noconfirm grub efibootmgr
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
  pacman -S --noconfirm grub
  grub-install --target=i386-pc "${DISK}"
fi

grub-mkconfig -o /boot/grub/grub.cfg

echo ">>> setup-post.sh completed successfully."