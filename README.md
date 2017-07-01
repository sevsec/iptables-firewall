# iptables-firewall
Simple whitelist-based firewall that uses iptables for rule enforcement.



# Story, background
I wrote some autoation for all the Virtual Private Servers I owned a few years back. Services like Digital Ocean, Cloud at Cost, SSD Virt, Lightsail, etc do not typically include any sort of mechanism to protect your VPS, leaving them open to the world unless you take the time to configure something on your own. This means that your VPS is open to the world, being hammered on within 1 second of going live on the public internet. Aside from the security risk, it's annoying to have people knocking on your door constantly, so I decided to setup an iptables-based firewall on my boxes. I went with iptables as it is typically installed by default on most distros, so creating automation around iptables to prevent my VPS from being hammered was fairly trivial.

Since I've had this for years, and wanted to start contributing something to the internet, I've chosen this as my first project to push to github.

This firewall is whitelist-based, as it was much easier for me to specify which IPs were allowed on my VPS rather than use software like fail2ban or try to block the entire internet. (I am debating adding a blacklist feature - we'll see.)


# Features:
- IP-based whitelist - IPs in whitelist will have full access to all ports on box
- Port-based whitelist - TCP/UDP ports may be opened to the world
- Hostname-resolving capability - Will automatically resolve IPs behind hostnames and add those to the IP whitelist


# Installation:
1. Run 'git clone https://github.com/sre3219/iptables-firewall'
2. Enter the repo using 'cd iptables-firewall'
3. Run the included setup.sh script using sudo: "sudo ./setup.sh"
4. The default install mode is simple, which will prompt you for all the necessary configuration information.
  4a. If you stick with the simple installation mode, follow the on-screen instructions.
  4b. If you decide to go with the advanced mode, you will have to modify the config files located in /etc/iptables-firewall/config on your own.
5. The setup script will automatically download and install any dependencies.
6. If you chose the simple installation mode in step 4, everything should be setup and good to go. Your machine will now only accept connections from the IPs you specified, as well as connections from ALL IPS on the protocols and ports you specified.

Note: If you chose the advanced installation mode, the requisite dependencies will be installed and all necessary directories/files will be created. No changes will be made to iptables, however, and you will need to run iptables-firewall.sh on your own. Additionally, you should consider copying the included cron file in config/cron-file to /etc/cron.d/.


# TODO:
- IPv6 support (duh)
- getopts for setup script, to allow further automation of the installation, setup, and configuration of this package
- getopts for the iptables-firewall script, to allow greater flexibility in which configs are used
- Potentially create a blacklist version of this package, to ban IPs rather than use a whitelist model
