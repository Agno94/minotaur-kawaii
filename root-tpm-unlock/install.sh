#!/bin/bash

sourcedir=`dirname $0`

[[ ! -d /etc/initramfs-tools ]] && (echo Missing /etc/initramfs-tools; exit 1)

mkdir -p /etc/initramfs-tools/hooks
install -T -m 744 $sourcedir/tpm2-load.initramfs-hook /etc/initramfs-tools/hooks/tpm2-load

install -T -m 744 $sourcedir/tpm2-cryptsetup.sh /etc/initramfs-tools/tpm2-cryptsetup

