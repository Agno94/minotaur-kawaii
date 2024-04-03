#!/bin/bash

BASEPATH=$(dirname $0)
SALT=$(cat $BASEPATH/user-home-dir-salt.hex)
argon2 $SALT -id -m 13 -t 10 -p 4 -l 32 -r
