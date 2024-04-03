#!/bin/bash
xxd -p -c999 /run/keystore/rpool/system.key > user-home-dir-salt.hex
#dd if=/dev/urandom bs=8 count=1 | xxd -p -c999
