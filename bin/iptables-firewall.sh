#!/bin/bash
# iptables-firewall by Sean Evans
# https://github.com/sre3219/iptables-firewall
pushd /etc/iptables-firewall/

if [[ $(which iptables > /dev/null; echo $?) -ne 0 ]] || [[ $(which iptables-save > /dev/null; echo $?) -ne 0 ]]; then
  echo "iptables and iptables-save required. Try re-installing."
  echo "Exiting ..."
  exit 1
else
  IPTABLES=$(which iptables)
  IPTABLES_SAVE=$(which iptables-save)
fi

WHITELIST=$(grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" config/whitelist.conf)
HOSTLIST_IPS=$(grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" config/hostname.ips)
TCP_ALLOWED=$(grep -oE "[0-9]{1,5}" config/tcp-ports.conf)
UDP_ALLOWED=$(grep -oE "[0-9]{1,5}" config/udp-ports.conf)
ICMP_ALLOWED=$(grep -oE "allow\_icmp\=[0-1]" config/icmp.conf | grep -oE "[0-1]")

$IPTABLES -P INPUT ACCEPT
echo "INPUT chain default policy set to ACCEPT ..."
$IPTABLES -F
echo "Flushed all tables ... "
$IPTABLES -X
echo "Deleted all user-defined chains ..."
$IPTABLES -Z
echo "Counters cleared ..."
IPTABLES -P INPUT DROP

echo "Adding localhost ..."
$IPTABLES -A INPUT -s 127.0.0.1 -j ACCEPT

# Add IPs and hostname IPs to ACCEPT chain
for IP in $WHITELIST; do
  echo "Adding $IP ..."
  $IPTABLES -A INPUT -s $IP -j ACCEPT
done

for IP in $HOSTLIST_IPS; do
  echo "Adding $IP ..."
  $IPTABLES -A INPUT -s $IP -j ACCEPT
done

# Add ports for TCP and UDP connections
for TPORT in $TCP_ALLOWED; do
  echo "Adding TCP $TPORT ..."
  $IPTABLES -A INPUT -p tcp --dport $TPORT -j ACCEPT
done

for UPORT in $UDP_ALLOWED; do
  echo "Adding UDP $UPORT ..."
  $IPTABLES -A INPUT -p udp --dport $UPORT -j ACCEPT
done

# Allow established TCP connections
$IPTABLES -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# Default drop
$IPTABLES -A INPUT -p udp -j DROP
$IPTABLES -A INPUT -p tcp --syn -j DROP
echo "INPUT chain default policy set to DROP ...."

if [[ "$ICMP_ALLOWED" -eq 0 ]]; then
  $IPTABLES -I INPUT -p icmp -j DROP
fi

# Save the rules so they are persistent on reboot.
bash -c "$IPTABLES_SAVE > /etc/iptables/rules.v4 > /dev/null 2>&1"
popd
