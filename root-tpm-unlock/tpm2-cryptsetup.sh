#!/bin/sh

if [ "$CRYPTTAB_TRIED" -lt "1" ]
then
  echo "Cryptsetup script" 1>&2
  echo "Trying unlock $CRYPTTAB_SOURCE ($CRYPTTAB_NAME) with TPM" 1>&2
  echo "Trying unlock $CRYPTTAB_SOURCE ($CRYPTTAB_NAME) with TPM" > /dev/kmsg
  tpm2-initramfs-tool unseal --pcrs 0,1,2,3,5,7 --banks SHA256
  echo Returning secret 1>&2
  echo Returning secret > /dev/kmsg
  exit 0
fi

/usr/bin/askpass "Passphrase for $CRYPTTAB_SOURCE ($CRYPTTAB_NAME): "

