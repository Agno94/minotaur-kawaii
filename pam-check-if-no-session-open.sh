#!/usr/bin/bash

set -eux

OPEN_SESSIONS=$(loginctl list-sessions --no-legend)

if python3 -c 'import sys, re; pamuser=sys.argv[1]; sys.exit(0 if len([user for user in map(lambda line: re.split(r"\s+", line.strip(), maxsplit=3)[2], sys.stdin.readlines()) if user==pamuser]) else 1)' $PAM_USER <<< $OPEN_SESSIONS
then
 false
else
 true
fi
