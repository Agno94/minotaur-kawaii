#!/bin/bash

#set -x

#kernel_version="6.5.0-14-generic"
#linux_path="/boot/vmlinuz-$kernel_version"
#initrd_path="/boot/initrd.img-$kernel_version"
esp_path="/boot/efi"
initrd_path="/boot/initrd.img"
linux_path="/boot/vmlinuz"
sbkeys_path="/root/sbkeys/DB-agno2401016"
splash_file_path="/opt/mkuki/uki_splash_ubuntu_framework.bmp"
efi_path="linuxUKI/ubuntu.efi"
stub_path=`ls -1 /var/lib/flatpak/runtime/org.gnome.Platform/x86_64/*/*/files/lib/systemd/boot/efi/linuxx64.efi.stub|sort -r|head -n 1`
#stub_path="/var/lib/flatpak/runtime/org.gnome.Platform/x86_64/45/3ef40ce469661e017e94259d2faa3056c437e492f077d2684208bb53a282f8b6/files/lib/systemd/boot/efi/linuxx64.efi.stub"

align="$(objdump -p $stub_path | awk '{ if ($1 == "SectionAlignment"){print $2} }')"
align=$((16#$align))
osrel_offs="$(objdump -h "$stub_path" | awk 'NF==7 {size=strtonum("0x"$3); offset=strtonum("0x"$4)} END {print size + offset}')"
osrel_offs=$((osrel_offs + "$align" - osrel_offs % "$align"))
cmdline_offs=$((osrel_offs + $(stat -Lc%s "/usr/lib/os-release")))
cmdline_offs=$((cmdline_offs + "$align" - cmdline_offs % "$align"))
splash_offs=$((cmdline_offs + $(stat -Lc%s "/etc/cmdline")))
splash_offs=$((splash_offs + "$align" - splash_offs % "$align"))
initrd_offs=$((splash_offs + $(stat -Lc%s "$splash_file_path")))
initrd_offs=$((initrd_offs + "$align" - initrd_offs % "$align"))
#initrd_offs=$((cmdline_offs + $(stat -Lc%s "/etc/cmdline")))
#initrd_offs=$((initrd_offs + "$align" - initrd_offs % "$align"))
linux_offs=$((initrd_offs + $(stat -Lc%s "$initrd_path")))
linux_offs=$((linux_offs + "$align" - linux_offs % "$align"))

echo -- Generating UKI image $efi_path ...

temp_file_name=$(mktemp)

objcopy \
    --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=$(printf 0x%x $osrel_offs) \
    --add-section .cmdline="/etc/cmdline" \
    --change-section-vma .cmdline=$(printf 0x%x $cmdline_offs) \
    --add-section .splash="$splash_file_path" \
    --change-section-vma .splash=$(printf 0x%x $splash_offs) \
    --add-section .initrd="$initrd_path" \
    --change-section-vma .initrd=$(printf 0x%x $initrd_offs) \
    --add-section .linux="$linux_path" \
    --change-section-vma .linux=$(printf 0x%x $linux_offs) \
    "$stub_path" "$temp_file_name"

if [ -f "$esp_path/EFI/$efi_path" ]; then
  echo -- Saving old image to "$esp_path/EFI/$efi_path.old" ...
  mv "$esp_path/EFI/$efi_path" "$esp_path/EFI/$efi_path.old"
fi

echo -- Signing UKI image

sbsign \
  --key /root/sbkeys/DB-agno2401016.key \
  --cert /root/sbkeys/DB-agno2401016.crt \
  --output "$esp_path/EFI/$efi_path" \
  "$temp_file_name"

