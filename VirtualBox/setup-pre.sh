#!/bin/bash
set -e

# Keyboard layout
loadkeys pt-latin1

# Enable NTP
timedatectl set-ntp true

# === Partition Disk ===
# BIOS/MBR layout:
# /dev/sda1 = swap (4G)
# /dev/sda2 = root (rest of disk)

sfdisk /dev/sda <<EOF
label: dos
label-id: 0xdeadbeef
device: /dev/sda
unit: sectors

/dev/sda1 : size=4G, type=82, bootable
/dev/sda2 : type=83
EOF

# === Format Partitions ===
mkswap /dev/sda1
swapon /dev/sda1
mkfs.ext4 /dev/sda2

# === Mount ===
mount /dev/sda2 /mnt

# === Install Base System ===
pacstrap /mnt base linux linux-firmware vim git

# === Generate fstab ===
genfstab -U /mnt >> /mnt/etc/fstab

# === Copy post-install script into chroot ===
cat > /mnt/setup-post.sh <<"EOS"
#!/bin/bash
set -e

# Timezone & clock
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

# Locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo "myarch" > /etc/hostname

# Root password
echo "root:Admin!123" | chpasswd

# Bootloader (BIOS)
pacman -S --noconfirm grub
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# Enable networking
pacman -S --noconfirm networkmanager sudo
systemctl enable NetworkManager

EOS

chmod +x /mnt/setup-post.sh

# === Chroot into system and run post script ===
arch-chroot /mnt /setup-post.sh

# Cleanup
rm /mnt/setup-post.sh

echo ">>> Installation complete! Unmount and reboot."
