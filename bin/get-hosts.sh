#!/bin/bash

pushd /etc/iptables-firewall/config/

if [ -e hostname.list ]; then
  rm hostname.ips
  HOSTNAME_LIST=$(grep -oE ".*" hostname.list | grep -v "#")
else
  echo "No host.list file found under /etc/iptables-firewall/config/"
  exit 1
fi

for HOSTNAME in $HOSTNAME_LIST; do
  echo -ne "Host: $HOSTNAME, "
  IP=$(host $HOSTNAME | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")

  if [[ "$?" -eq 0 ]]; then
    echo "Adding:"
    echo "$IP"
    echo $IP >> hostname.ips
  fi
done

