#!/usr/bin/bash

set -eu 

TIME=$(date "+%y%m%dT%H%M%S")
echo "$TIME;$PAM_USER" >> "/opt/zfs-unlock/unlocker-logins.log"

SALT=$(cat /run/keystore/rpool/user-home-dir-salt.hex)
PASS=$(cat -)
HEXKEY=$(argon2 $SALT -id -m 13 -t 10 -p 4 -l 32 -r <<< $PASS)

zfs get local.agnopc.homedir:user -s local -H -o name,value | while read volname user
do
    echo Found $volname of user $user
    # Filter on user property local.agnopc.homedir:user. It should match
    # the user that we are logging in as ($PAM_USER)
    [[ $user == $PAM_USER ]] || continue
    echo Unlocking $volname ...

    # Unlock and mount the volume
    zfs load-key "$volname" <<< "$HEXKEY" || continue
    zfs mount "$volname" || continue
    echo Unlocked and mounted $volname
done

zfs get local.agnopc.homedir:user -s inherited -H -o name,value -t filesystem | while read volname user
do
    [[ $user == $PAM_USER ]] || continue
    echo Mounting $volname ...
    zfs get mounted -H $volname || continue
    zfs mount "$volname" || continue
    echo Mounted $volname || continue
    zfs get mounted -H $volname
done

#zfs get local.agnopc.homedir:parent -s local -H -o name,value | while read volname user
#do
#    [[ $user == $PAM_USER ]] || continue
#    echo Mounting $volname ...
#    zfs mount "$volname" || continue
#done

echo Done

exit 0

