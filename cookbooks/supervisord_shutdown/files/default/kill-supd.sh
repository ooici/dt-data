#!/bin/bash

echo "Attempting to gracefully kill supervisord processes"

rc=0
while [ $rc -eq 0 ]; do

    pkill -f supervisord

    rc=$?

    if [ $rc -ne 0 ]; then
        sleep 1
    fi
done
