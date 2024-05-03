#!/bin/sh

[ "$CRYPTTAB_TRIED" -lt "1" ] && exec tpm2-initramfs-tool unseal --pcrs 0,1,2,3,5,7

/usr/bin/askpass "Passphrase for $CRYPTTAB_SOURCE ($CRYPTTAB_NAME): "

