Tools (started on Ubuntu Mantic Minotaur) for a System with Full-Disk and Home-Directory-Dataset ZFS-based encryption and TPM unlock
------------------------

### Motivation and inspirations

Some months ago I read an [blog post by L. Poettering (2021-09-23)](https://0pointer.net/blog/authenticated-boot-and-disk-encryption-on-linux.html) where he underlines several problems with how current Linux distributions deploy full-disk encryption (FDE).
The article outlines the technologies available, how they are commonly used by distros and some vulnerabilities of these installations.
These vulnerabilities become easily exploitable in case we add automatic TPM2 unlock of the encrypted disk/pool/partition.
The article goes on to present an idea of solutions. I very much disliked this part of the article. I found the solutions proposed impractical today and somewhat inconvenient.
Another part of the article that I liked is the idea of a user home directory encrypted with a user password and/or token.

On my personal daily driver system, I had Ubuntu 23.10 (mantic minotaur), mostly installed on a single ZFS pool.

The files in this repository are some results of my tinkering with the goals in mind:
- a "secure" implementation of FDE
- an automatic unlock of FDE with TPM2 if the device hasn't been tampered with
- having any user home directory encrypted with the user's password 
- continue relying on ZFS-based dataset encryption
- using the fingerprint sensors for authentication if the user password has been already entered/the user home filesystem/dataset is already unlocked
- keep the possibility to boot with shim+GRUB(without TPM unlock) if necessary as a recovery/backup/diagnostic insecure boot alternative

Most of my work has been inspired by these two posts/articles:
- [The ultimate guide to Full Disk Encryption ... (Philippe Daouadi 2022-04-06)](https://blastrock.github.io/fde-tpm-sb.html) is a guide for a secure FDE on Debian.
- [Linux homedir encryption (Jørn Christensen 2020-04-06)](https://talldanestale.dk/2020/04/06/zfs-and-homedir-encryption/) is a guide for unlocking a zfs dataset during Pluggable Authentication Module(PAM) authentication

### What is used

OS side:
- ZFS native encryption with multiple encryption roots
- Unified Kernel Image (UKI) generated starting from systemd's Linux EFI Stub
- Modifications of the initramfs (some new shell scripts, edit of an existing one, use of [tpm2-initramfs-tool](https://github.com/timchen119/tpm2-initramfs-tool))
- Tweaks of PAM configuration using `pam_exec.so` and `pam_fprintd`

Firmware side(prerequisite/setup):
- UEFI/BIOS password (always a good idea, required if you have something like a "*Add this db key to secure boot*" option available)
- UEFI Boot Menu to select the right boot option
- Secure Boot with a new key ideally added to the `db` list

### How did the Ubuntu installer set up ZFS encryption

The system was originally installed with a Ubuntu 22.04 ISO and later upgraded. The setup program created a main zpool called `rpool` for most of the system. All filesystems in the pool were encrypted under a single encryption root. The encryption key was saved in a small zvol called `keystore`. This volume was encrypted with the password I entered during installation using LUKS, and formatted with ext4. Scripts in the initramfs ask for the keystore password and mount it in `/run/keystore/rpool/` before unlocking and mounting the root filesystem.

I also have the EFI System Partition (ESP) and I had a second zpool for GRUB, mounted in `/boot`, that I deleted in favor of a single ext4 partition (as stated above I've kept it as an unsecured backup option).

Ubuntu 23.10 does not use systemd in the initramfs.

### How to use the content of this repository

I think I explained my goal and my situation. If not ask/open an issue.

Maybe I'll maybe write some setup scripts for my configuration.
Still, they will be specific to my system.

Anyone interested should first read(or at least skim) the links above (you can skip Poettering's solutions if you are not interested), understand the problems and technologies and copy/adapt/apply the content of this repository with care. You should understand what you are doing.

I'm writing a guide, in Italian, to cover in-depth TPM2 unlock. It won't cover the rest of the stuff in the repository and is meant for a smaller audience.
