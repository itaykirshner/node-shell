#!/bin/bash

cat << EOF | chroot /host
cd /var/log/containers/
ls | grep $1 | xargs cat
EOF
