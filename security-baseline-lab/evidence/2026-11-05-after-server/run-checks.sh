#!/bin/bash
echo "=== A1 UID 0 accounts ==="
awk -F: '$3==0{print $1}' /etc/passwd
echo "=== A2 Empty passwords ==="
awk -F: '($2==""){print $1}' /etc/shadow
echo "=== A3 Regular accounts ==="
awk -F: '$3>=1000{print $1}' /etc/passwd
echo "=== S1/S2 SSH settings ==="
sshd -T | grep -E "^(permitrootlogin|passwordauthentication)"
echo "=== F1 Firewall ==="
ufw status | head -1
echo "=== F2 Listening ports ==="
ss -tulpn
echo "=== W1 Banner config ==="
grep -hE "^(ServerTokens|ServerSignature)" /etc/apache2/conf-enabled/*.conf
echo "=== W2 /backup/ status code ==="
curl -s -o /dev/null -w "%{http_code}\n" http://localhost/backup/
echo "=== W3 Modules ==="
apache2ctl -M 2>/dev/null | grep autoindex
echo "=== W4 World-writable in /var/www ==="
find /var/www -perm -0002 ! -type l
echo "=== W5 HTTPS headers ==="
curl -skI https://localhost/
echo "=== M1 Unattended upgrades ==="
systemctl is-enabled unattended-upgrades
echo "=== M2 Upgradable packages ==="
apt list --upgradable 2>/dev/null
echo "=== L1 rsyslog ==="
systemctl is-active rsyslog
echo "=== L2 fail2ban ==="
systemctl is-active fail2ban
