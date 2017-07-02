#!/bin/bash
# iptables-firewall by Sean Evans
# https://github.com/sre3219/iptables-firewall

if [[ "$1" =~ ^(\-|\-\-)[hHhelpHELP] ]]; then
  # TODO: getopts
  echo "Setup iptables-firewall. Installs all dependencies, copies to /etc/iptables-firewall,"
  echo "and allows for both Simple and Advanced installation modes."
  echo "Usage: sudo ./setup.sh"
  exit 0
elif [[ $(whoami) != "root" ]]; then
  echo "This script requires root privileges. You must run it using 'sudo $0'."
  exit 1
fi

DEPENDENCIES="iptables iptables-persistent iptables-save host"

install_depends() {
  if [[ $(which yum > /dev/null 2>&1; echo $?) -eq 0 ]]; then
    echo "Red Hat-based distro detected, updating and installing using yum ..."
    yum update > /dev/null 2>&1
    yum install -y $DEPENDS > /dev/null 2>&1
    if [[ "$?" -eq 0 ]]; then
      echo "Dependency installations successful."
    else
      echo "Issue installing dependencies, exiting."
      exit 1
    fi
  elif [[ $(which apt > /dev/null 2>&1; echo $?) -eq 0 ]]; then
    echo "Debian-based distro detected, updating and installing using apt ..."
    apt update > /dev/null 2>&1
    apt install -y $DEPENDS > /dev/null 2>&1
    if [[ "$?" -eq 0 ]]; then
      echo "Dependency installations successful."
    else
      echo "Issue installing dependencies, exiting."
      exit 1
    fi
  elif [[ $(which pacman > /dev/null; echo $?) -eq 0 ]]; then
    echo "Arch-based distro detected, updating and installing using pacman ..."
    pacman -Su > /dev/null 2>&1
    pacman install -y $DEPENDS > /dev/null 2>&1
    if [[ "$?" -eq 0 ]]; then
      echo "Dependency installations successful."
    else
      echo "Issue installing dependencies, exiting."
      exit 1
    fi

  else
    echo "Unable to determine package manager!"
    echo "(Are you doing something naughty, like using Gentoo? (Support coming soon)."
    # TODO: prompt to continue or fail?
    exit 1
  fi
}

check_depends() {
  if [[ ! -d /etc/iptables-firewall ]]; then
    echo "Installing to /etc/iptables-firewall ..."
    mkdir /etc/iptables-firewall > /dev/null 2>&1
    cp -rfu . /etc/iptables-firewall/ > /dev/null 2>&1
  elif [[ "$1" -eq 1 ]]; then
    echo "/etc/iptables-firewall appears to exist."
    echo "You may:"
    echo "  [R]einstall over the existing installation, keeping your current config intact."
    echo "  [O]verwrite the existing installation, removing previous configs (fresh install)."
    echo "  [C]ancel this process, not having modified anything (DEFAULT)"
    read -p"[r/o/C]: " PROMPT

    case "$PROMPT" in
      "R" | "r") # Reinstall - keeps old configs
        cp -ru ./bin /etc/iptables-firewall/ > /dev/null 2>&1
        cp -ru * /etc/iptables-firewall/ > /dev/null 2>&1
        ;;
      "D" | "d") # Delete - removes all old files, cean install
        rm -rf /etc/iptables-firewall/ > /dev/null 2>&1
        mkdir /etc/iptables-firewall > /dev/null 2>&1
        cp -rfu . /etc/iptables-firewall/ > /dev/null 2>&1
        ;;
      "C" | "c") # Exit
        echo "Exiting."
        exit 1
        ;;
      * | ?) # Wut
        echo "Invalid option chosen, exiting ..."
        exit 1
        ;; 
    esac
  else
    echo "Backing up what appears to be an old version of iptables-firewall ..."
    mv /etc/iptables-firewall /etc/iptables-firewall.OLD > /dev/null 2>&1
    mkdir /etc/iptables-firewall > /dev/null 2>&1
    cp -rfu . /etc/iptables-firewall/ > /dev/null 2>&1
  fi
}

simple_install() {
  # Optionally prompts the user for IPs/host names
  echo "Simple install" #
  check_depends "0"
  install_depends

  echo "Setup appears to be succesful."
  read -p"Proceed with adding IPs and hostnames to config? [Y/n]: " PROMPT

  if [[ "$PROMPT" =~ [nN] ]]; then
    echo "Okay, manual configuration it is."
    return
  fi

  # Setup IPs - TODO: check for valid IPs
  echo "Time to setup the ALLOWED IP list. Please enter all allowed IPs, separated by any char (space, comma, etc - NO EOL): "
  read RIP
  grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" <<< $RIP > /etc/iptables-firewall/config/whitelist.ips > /dev/null 2>&1

  # Setup TCP ports
  echo "Please enter all allowed TCP ports (22, 80, 443, etc). Keep in mind that these ports will be open to the world: "
  read TPORTS
  for PORT in `grep -oE "[0-9]{1,5}" <<< $TPORTS`; do
    if [[ "$PORT" -gt 0 ]] && [[ "$PORT" -lt 65536 ]]; then
      echo $PORT >> /etc/iptables-firewall/config/tcp-ports.conf
    fi
  done

  # Setup UDP ports
  echo "Please enter all allowed UDP ports. Keep in mind that these ports will be open to the world: "
  read UPORTS
  for PORT in `grep -oE "[0-9]{1,5}" <<< $UPORTS`; do 
    if [[ "$PORT" -gt 0 ]] && [[ "$PORT" -lt 65536 ]]; then
      echo $PORT >> /etc/iptables-firewall/config/tcp-ports.conf 
    fi
  done

  # Enable ICMP?
  read -p"Enable ICMP (disabled by default)? [y/N]: " ICMP
  if [[ "$ICMP" =~ [yY] ]]; then
    sed -i 's/allow\_icmp\=0/allow\_icmp\=1/g' /etc/iptables-firewall/config/icmp.conf
  fi

  # Setup cron job
  echo "You have the option of automating iptables-firewall. A script will resolve hostname(s) to IP(s)"
  echo "every so often, as well as update the iptables rules to reflect the latest changes."
  echo "This means that any IP changes to hostnames, as well as whitelist updates, will automatically"
  echo "be applied to your firewall rules."
  echo "(Note: hostnames will be resolved every 15 mins and firewall updates will be made every 30 mins.)"
  echo ""
  read -p"Would you like to enable this automation? [Y/n]: " PROMPT

  if [[ "$PROMPT" =~ [nN] ]]; then
    echo "Okay, automation will not be enabled. You will need to manually run all the scripts on your own,"
    echo "or setup your own cron job."
    return
  fi

  cp -f ../config/cron-file/run_firewall_script.cron /etc/cron.d/
}

advanced_install() {
  # Requires that the user update all configs themselves, including cron job
  echo "Advanced install" #
  check_depends "1"
  install_depends
}

echo "Welcome message" #
echo ""
while true; do
  echo "This script will setup iptables-firewall for you."
  echo "You have the option of running: "
  echo "  [S]imple setup and installation (recommended)"
  echo "  [A]dvanced setup and installation (necessities will be installed, you will have to configure manually)"
  echo "  [Q]uit this setup and leave the system unmodified"
  echo ""
  read -p"Please choose: [S/a/q]: " PROMPT
    if [[ "$PROMPT" =~ [Aa] ]]; then
      advanced_install
      break
    elif [[ "$PROMPT" =~ [Qq] ]]; then
      echo "Exiting ..."
      exit 0
    else
      simple_install
      break
    fi
done
