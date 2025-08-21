# 📖 Arch Install Automation

This repo contains helper scripts to bootstrap an Arch Linux install.

---

# 📝 What the pre-install script does

- Detects if the computer is **BIOS or UEFI**
- Wipes and partitions the disk (creates **swap + root**, and an EFI partition if UEFI)
- Formats and mounts the partitions
- Installs the **base Arch Linux system** and some basic tools
- Generates the **fstab** (mount points)
- Drops the post-install script into the new system and runs it

---

# 📝 What the post-install script does

- Sets the **timezone**, clock, and **locale**
- Configures **hostname** and **hosts file**
- Sets the **root password**
- Installs **microcode updates** for Intel/AMD CPUs
- Installs and enables **NetworkManager** (so networking works after reboot)
- Installs the bootloader (**GRUB**) in the correct mode (BIOS or UEFI)
- Generates the **GRUB configuration**
- Finishes up so you can reboot into your new Arch system

---

👉 **Basically:**  
**Pre = disk setup + base system.**  
**Post = system config + bootloader.**

## 🖥️ VirtualBox (BIOS install)

Scripts are in `VirtualBox/`.<br>
They assume:

- **Legacy BIOS** (not UEFI)
- **Disk:** `/dev/sda`
- **Partition layout:**
  - `/dev/sda1` → swap (4G)
  - `/dev/sda2` → root (`/`)

### Steps

1. Boot from the Arch ISO in VirtualBox.
2. Clone this repo inside the live environment (or copy scripts in manually).
3. Run the pre-install script:
    ```sh
    cd VirtualBox
    chmod +x setup-pre.sh
    ./setup-pre.sh
    ```
    - This partitions the disk, formats, mounts, pacstraps, and copies the post script.
    - It automatically chroots and runs `setup-post.sh`.
4. When it finishes:
    ```sh
    umount -R /mnt
    reboot
    ```

5. Log in as `root` with the password defined in the script (**default:** `Admin!123`).
6. Create a non-root user and configure `sudo`.

---

## 💻 Hardware Install (BIOS or UEFI)

Scripts are in `Hardware/`.<br>
These cover both BIOS and UEFI setups. Adjust depending on your machine:

### For BIOS (MBR boot):

- Target disk is usually `/dev/sda` (could differ).
- Use:  
  `grub-install --target=i386-pc /dev/sdX`
- Partition scheme: swap + root (like the VirtualBox setup, but adjust sizes as needed).

### For UEFI (GPT boot):

- Target disk is often `/dev/nvme0n1` or `/dev/sda`.
- You need an EFI System Partition (ESP):
    - `/dev/nvme0n1p1` = 512M, FAT32, mounted at `/boot`
    - `/dev/nvme0n1p2` = swap (optional)
    - `/dev/nvme0n1p3` = root `/`
- Use:
  ```
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
  ```
- Install `efibootmgr` alongside grub.

### Steps

1. Boot from the Arch ISO on your real machine.
2. Get this repo (or copy the scripts in).
3. Run the pre-install script:
    ```sh
    cd Hardware
    chmod +x setup-pre.sh
    ./setup-pre.sh
    ```
    - For BIOS: uses `i386-pc` GRUB target
    - For UEFI: uses `x86_64-efi` GRUB target and an ESP
4. When it finishes:
    ```sh
    umount -R /mnt
    reboot
    ```
5. Log in as `root`, set up your user and dotfiles.

---

> ⚡ **Tip:** Always double-check the disk (`/dev/sda` vs `/dev/nvme0n1`) with:
> ```sh
> lsblk
> ```
> before running the scripts.