#!/bin/bash

echo "usage: sudo $0 [luks_device_path] [luks_tmp2_new_secret_path] [key_length] [argonid_memory] [argonid_threads] [key_slot_id]"

core_count=`grep '^cpu\\scores' /proc/cpuinfo | uniq | awk '{print $4}'`

device=${1:-"/dev/zd0"}
secret=${2:-"/root/luks_tpm2_secret"}
key_lenght=${3:-"40"}
# NOTA: Possibile aumentare pbkdf-memory ma consiglio di restare su valori inferiori alla cache della CPU
kdf_mem=${4:-"524288"}
kdf_threads=${5:-$core_count}
slot=${6:-"2"}

echo "Creating random secret in $secret ..."
if [ -f $secret ]
then
 echo "A file exists in $secret, will be overwritten, press ENTER to continue or stop this script"
 read
fi
dd if=/dev/random bs=64 count=1 | base64 > $secret
truncate -s $key_lenght $secret
chmod 400 $secret

echo "Adding secret to key-slot $slot of device $device with preffered priority ..."
echo cryptsetup luksAddKey $device $secret -S $slot --pbkdf-force-iterations=4 --pbkdf-memory=$kdf_mem --pbkdf-parallel=$kdf_threads
cryptsetup luksAddKey $device $secret -S $slot --pbkdf-force-iterations=4 --pbkdf-memory=$kdf_mem --pbkdf-parallel=$kdf_threads
echo cryptsetup config -S $slot --priority prefer $device
cryptsetup config -S $slot --priority prefer $device

echo Completed! Check logs above pls!

