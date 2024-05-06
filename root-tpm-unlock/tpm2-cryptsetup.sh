#!/bin/sh

log() { echo $1 >&2; echo $1 > /dev/kmsg; }

log "crypt-tpm-unlock: Asked for encryption password for $CRYPTTAB_SOURCE ($CRYPTTAB_NAME)"

if [ "$CRYPTTAB_TRIED" -lt "1" ]
then
 secret=`tpm2-initramfs-tool unseal --pcrs 0,1,2,3,7`
 if [ $? -eq 0 ]
 then
  log "crypt-tpm-unlock: Returning TPM2 secret"
  echo -n $secret
  exit 0
 fi
 log "crypt-tpm-unlock: TPM2 secret not available"
fi

log "crypt-tpm-unlock: Asking for password"

/usr/bin/askpass "Passphrase for $CRYPTTAB_SOURCE ($CRYPTTAB_NAME): "

