# Set the keyboard layout to Portuguese (Latin1)
loadkeys pt-latin1
# Set the system clock to UTC
timedatectl set-ntp true
# Set the system clock to UTC
timedatectl set-timezone UTC
# Partition the disk
fdisk /dev/sda
o
n
p
1
2048
+1G
a
n
p
enter
+4G
n
p
3
enter
enter
t
1
ef
t
2
82
t
3
83
w
# Format the partitions
mkfs.fat -F32 /dev/sda1
mkswap /dev/sda2
mkfs.ext4 /dev/sda3
# Mount the partitions
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
swapon /dev/sda2
# Install the base system
pacstrap /mnt base linux linux-firmware
# Generate the fstab file
genfstab -U /mnt >> /mnt/etc/fstab
# Change root into the new system
arch-chroot /mnt
# Set the timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
# Set the locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
# Set the hostname
echo "myarch" > /etc/hostname
passwd # Set the root password ex: Admin!123
# Install the bootloader
pacman -S grub efibootmgr
Y
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
# Exit the chroot environment
exit
# Unmount the partitions
umount -R /mnt
# Reboot the system
reboot
# Might need to change boot order in BIOS
