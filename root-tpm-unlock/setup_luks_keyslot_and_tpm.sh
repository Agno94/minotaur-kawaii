#!/bin/bash

echo "usage: sudo $0 [luks_device_path] [luks_tmp2_new_secret_path] [argonid_memory] [argonid_threads] [key_slot_id]"

core_count=`grep '^cpu\\scores' /proc/cpuinfo | uniq | awk '{print $4}'`

device=${1:-"/dev/zd0"}
secret=${2:-"/root/luks_tpm2_secret"}
# NOTA: Possibile aumentare pbkdf-memory ma consiglio di restare su valori inferiori alla cache della CPU
kdf_mem=${3:-"524288"}
kdf_threads=${4:-$core_count}
slot=${5:-"2"}

echo "Creating random secret in $secret ..."
if [ -f $secret ]
then
 echo "A file exists in $secret, will be overwritten, press ENTER to continue or stop this script"
 read
fi
dd if=/dev/random bs=30 count=1 | base64 > $secret
chmod 400 /root/luks_tpm2_secret

echo "Adding secret to key-slot $slot of device $device with preffered priority ..."
echo cryptsetup luksAddKey $device $secret -S $slot --pbkdf-force-iterations=4 --pbkdf-memory=$kdf_mem --pbkdf-parallel=$kdf_threads
cryptsetup luksAddKey $device $secret -S $slot --pbkdf-force-iterations=4 --pbkdf-memory=$kdf_mem --pbkdf-parallel=$kdf_threads
echo cryptsetup config -S $slot --priority prefer $device
cryptsetup config -S $slot --priority prefer $device

echo Done!
