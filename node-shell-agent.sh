#!/bin/bash

function print_help() {
  echo
  echo -e "Node Shell v0.1"
  echo -e "---------------"
  echo -e "Purpose: Run linux commands on managed Kubernetes hosts. DNS and network diagnostics commands are also available."
  echo
  echo -e "Usage: node-shell -c \"<command string>\" | ns -c \"<command string>\""
  echo
  echo -e "Examples:"
  echo -e "\tnode-shell -c \"journalctl -u kubelet --since '2d ago' | less\""
  echo -e "\tnode-shell -c \"docker ps -a\""
  echo -e "\tns -c \"service kubelet restart\""
  echo -e "\tns -c \"nslookup www.google.com\""
  echo
  exit
}

if [ $# -eq 0 ]
  then
    print_help
    exit
fi

while getopts c: flag
do
    case "${flag}" in
        c) cmd=${OPTARG};;
    esac
done

cat << EOF | chroot /host
eval "$cmd"
EOF
