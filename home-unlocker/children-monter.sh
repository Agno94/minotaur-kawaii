#!/bin/bash
echo USER: $1
zfs get local.agnopc.homedir:user -s inherited -H -o name,value -t filesystem | while read volname user
do
    [[ $user == $1 ]] || continue
    echo Mounting $volname ...
    zfs get mounted -H $volname || continue
    zfs mount "$volname" || continue
    zfs get mounted -H $volname || continue
    echo Mounted $volname
done
