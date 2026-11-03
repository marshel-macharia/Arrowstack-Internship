# Remediation Plan: apache-web-01

**Project:** Security Baseline Assessment Lab (Arrowstack Cyber Security Internship, Project 1)
**Author:** Marshel Mburu Macharia
**Date:** 2026-11-03
**Version:** 1.0 (draft, before the fixes are applied)
**Source:** risk-register.md (F-01 to F-11)

## Principles
- Fix in ID order: High first (F-01 to F-04), then Medium, then Low.
- Each fix has a change, a validation (re-test of the check that failed) and a rollback.
- Every change gets a line in worklog.md and its output saved in `~/baseline-lab/evidence/2026-11-03/`.
- Rollback for everything: snapshot `apache-web-01-UNHARDENED-baseline`. Copy any new evidence to the Windows host first, because restoring a snapshot discards files created on the VM after it.
- Lockout risk: F-04 (SSH) and F-05 (firewall). Keep a second SSH session open while applying them.
- F-06 (updates) comes before the Apache configuration fixes (F-08 to F-10) so the upgrade does not clash with the edited config files.

```
mkdir -p ~/baseline-lab/evidence/2026-11-03    # creates the dated evidence folder; -p means no error if it exists
```

## F-01 (High): exposed /backup/ and db-dump.sql.bak
**Change (on apache-web-01)**
```
sudo find /var/www -iname 'backup' -o -iname 'db-dump*'   # locate the directory and the dump (the default -print covers both tests)
sudo rm -r <path of the backup directory>                  # delete the directory and the dump inside it
```
If the dump held real credentials, rotate them. In this lab the file is simulated, so state that in the report.

**Validate (from Kali)**
```
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.208.10/backup/db-dump.sql.bak
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.208.10/backup/
```
`-s` hides progress output, `-o /dev/null` discards the body, `-w '%{http_code}\n'` prints only the HTTP status. Expected result: 404 for both. Repeat with `https://` and add `-k` (accept the self-signed certificate).

**Rollback:** snapshot only. The file is deliberately not restored.

## F-02 (High): world-writable web root
**Change**
```
sudo chown -R www-data:www-data /var/www/apache-web-01/public_html            # owner and group back to the Apache user
sudo find /var/www/apache-web-01/public_html -type d -exec chmod 750 {} +      # directories: owner full, group read/enter, others none
sudo find /var/www/apache-web-01/public_html -type f -exec chmod 640 {} +      # files: owner read/write, group read, others none
```
These are the Stage 4 hardened values.

**Validate**
```
sudo find /var/www -perm -0002 ! -type l      # lists anything others can write to (symlinks excluded); expected: no output
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.208.10/    # site still serves: 200
```

**Rollback:** `chmod 777` on the directory (not recommended; for reference only).

## F-03 (High): unauthorized account testuser
**Change**
```
id testuser | tee ~/baseline-lab/evidence/2026-11-03/testuser-id-before.txt   # record its groups first (sudo or not decides the impact rating)
sudo deluser --remove-home testuser                                            # delete the account and its home directory
```

**Validate**
```
getent passwd testuser      # looks the user up in the account database; expected: no output
```
Then rerun the A3 check (regular accounts): only marshel and splunkfwd remain.

**Rollback:** recreate the account only if needed for a re-test (`sudo adduser testuser`).

## F-04 (High): SSH password authentication
**Precondition:** key login must work for `marshel` from every machine you log in from (Windows host, Kali), or this change locks you out.
```
ssh-keygen -t ed25519                      # on the client: create a key pair
ssh-copy-id marshel@192.168.208.10         # install the public key on the server
ssh marshel@192.168.208.10                 # confirm login works with the key, before changing anything
```

**Change**
```
echo 'PasswordAuthentication no' | sudo tee /etc/ssh/sshd_config.d/00-hardening.conf
```
sshd uses the first value it reads, and `00-` loads before files such as `50-cloud-init.conf`. `tee` is used so the file is written with sudo rights (a plain `>` redirect would not be).
```
sudo sshd -t                                   # syntax check; no output means OK
sudo sshd -T | grep -i passwordauthentication  # effective setting; expected: passwordauthentication no
```
sshd is normally socket-activated on Ubuntu, so new connections read the new config. Keep your existing session open until the test below passes.

**Validate (from Kali)**
```
ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password marshel@192.168.208.10
```
Expected: `Permission denied (publickey)`. Also rerun the S1/S2 check: `passwordauthentication no`, `permitrootlogin prohibit-password`.

**Rollback:** `sudo rm /etc/ssh/sshd_config.d/00-hardening.conf`.

## F-05 (Medium): firewall inactive
**Change**
```
sudo ufw default deny incoming     # drop anything not explicitly allowed
sudo ufw default allow outgoing    # the server can still reach updates, DNS and the Splunk forwarder target
sudo ufw allow 22/tcp              # allow SSH BEFORE enabling, or the session drops
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

**Validate**
```
sudo ufw status verbose            # expected: Status: active, default deny (incoming), rules for 22, 80, 443
```
From Kali, rerun `nmap -p- 192.168.208.10`: 22, 80 and 443 stay open, and the other ports change from "closed" (reset) to "filtered" (dropped). Save both outputs as before/after evidence.

**Rollback:** `sudo ufw disable`.

## F-06 (Medium): pending updates
**Change**
```
apt list --upgradable 2>/dev/null | wc -l     # count before (saves the "before" number; the first line is a header)
sudo apt update                                # refresh the package index so the upgradable list is current
sudo apt upgrade -y -o Dpkg::Options::="--force-confold"   # keep our edited config files instead of prompting
cat /var/run/reboot-required 2>/dev/null       # prints a message if a reboot is needed (kernel)
sudo reboot
```
If packages are "kept back", run `sudo apt full-upgrade`.

**Validate (after reboot)**
```
apt list --upgradable 2>/dev/null              # expected: only the "Listing..." header
uname -r                                       # kernel version now running
sudo ufw status | head -1                      # firewall still active
systemctl is-active apache2 ssh                # services came back up
```
Record any phased or deferred updates that remain and why.

**Rollback:** snapshot only.

## F-07 (Medium): fail2ban not active
**Change**
```
sudo apt install -y fail2ban
```
Ubuntu's package enables the sshd jail by default.

**Validate**
```
systemctl is-active fail2ban         # expected: active
sudo fail2ban-client status sshd     # expected: the sshd jail listed with its counters
```

**Rollback:** `sudo apt remove fail2ban`.

## F-08 (Medium): directory listing
**Change**
```
grep -rn 'Indexes' /etc/apache2/     # find where +Indexes is set (the vhost Directory block)
```
Edit that line to `Options -Indexes`, then:
```
sudo a2dismod autoindex              # disable the module that generates directory listings
sudo apachectl configtest            # syntax check; expected: Syntax OK
sudo systemctl reload apache2        # apply without dropping connections
```

**Validate**
```
sudo apachectl -M | grep autoindex   # expected: no output
```
Rerun the W3 check. From Kali, request a directory that has no index file: expected 403 or 404, no listing.

**Rollback:** `sudo a2enmod autoindex` and restore `Options +Indexes`.

## F-09 (Low): version banners
**Change**
```
grep -rnE 'ServerTokens|ServerSignature' /etc/apache2/     # find where they are set
```
Set `ServerTokens Prod` and `ServerSignature Off` there, then `sudo apachectl configtest && sudo systemctl reload apache2`.

**Validate (from Kali)**
```
curl -skI https://192.168.208.10/ | grep -i '^server'          # -I headers only, -k accept self-signed; expected: Server: Apache
curl -s http://192.168.208.10/nonexistent | grep -i 'server at'   # expected: no output (no footer signature)
```

**Rollback:** set the old values back.

## F-10 (Low): missing security headers
**Change**
```
sudo a2enmod headers     # enable mod_headers
```
Add to the HTTPS vhost (or `security.conf`):
```
Header always set X-Content-Type-Options "nosniff"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
Header always set Content-Security-Policy "default-src 'self'"
Header always set Strict-Transport-Security "max-age=300"
```
HSTS uses a short max-age (5 minutes) on purpose: with a self-signed certificate, a long HSTS lifetime would stop browsers from letting you click through the certificate warning. Then `sudo apachectl configtest && sudo systemctl reload apache2`.

**Validate (from Kali)**
```
curl -skI https://192.168.208.10/     # expected: all five headers present
```
Rerun the W5 check.

**Rollback:** remove the lines and reload.

## F-11 (Low): self-signed certificate, CN mismatch, no SAN
**Change:** back up the current certificate and key, then issue a new self-signed certificate that includes a SAN, and point the vhost at it.
```
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/apache-web-01.key -out /etc/ssl/certs/apache-web-01.crt \
  -subj "/CN=apache-web-01" -addext "subjectAltName=DNS:apache-web-01,IP:192.168.208.10"
```
`-x509` makes a self-signed certificate, `-nodes` skips the key passphrase so Apache can start unattended, `-addext` adds the SAN so the name and IP match.

**Validate**
```
openssl s_client -connect 192.168.208.10:443 </dev/null 2>/dev/null | openssl x509 -noout -ext subjectAltName
```
Expected: the DNS name and IP listed. Rerun Nikto: the CN mismatch should clear.

**Residual risk (accepted):** the certificate is still self-signed, so clients do not trust it. In production, use a certificate from a trusted CA.

## Validation after all fixes
1. Rerun the same 16 commands used for `checks-before.txt` and save `checks-after.txt` (expected: 16 of 16 passing; scope target: at least 14).
2. `sudo lynis audit system` on apache-web-01, saved as `lynis-after.txt`; compare the hardening index with the baseline of 61.
3. From Kali over the host-only link: `nmap -p-`, Nikto over HTTP and HTTPS, saved as `-after` files.
4. Hash the evidence folder with SHA-256 and copy it to the Windows host.
5. Take the snapshot `apache-web-01-REMEDIATED-final`.
6. Update the Status and Re-test result columns in risk-register.md, add the before/after table to the final report, and commit and push.

## Accepted residual risks
- F-11: certificate remains self-signed (lab environment).
- F-10: HSTS max-age kept short because of the self-signed certificate.
- F-03: the `testuser` password was never tested directly; the account is removed.