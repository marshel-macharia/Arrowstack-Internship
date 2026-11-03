# Work Log

## 2026-10-28
- Selected apache-web-01 (target) and Kali (assessor)
- Took snapshot apache-web-01-HARDENED-final
- Introduced intentional misconfigurations (banners, directory listing, 777 web root, UFW off, extra weak-password account)
- Took snapshot apache-web-01-UNHARDENED-baseline
- Captured evidence, hashed with SHA-256, copied to the host and verified
- Ran the 16-control baseline checks: 6 pass, 10 fail
- Committed the evidence to the repo (commit d1d23d4)
- Wrote scope statement and asset inventory

## 2026-10-29
- Confirmed apache-web-01 was in the UNHARDENED state
- Ran Lynis 3.1.6 on apache-web-01: hardening index 61, 262 tests, 1 warning, 49 suggestions (evidence/2026-10-29)
- Saved pending-updates list (~175 packages incl. apache2, openssh-server, openssl, sudo, kernel) and listening ports (22, 80, 443)
- First Nmap from Kali went via the VirtualBox NAT path (probes arrived from 192.168.208.1); results kept in nat-path-prelim
- Fixed Kali networking: added host-only eth1 192.168.208.30/24, kept eth0 10.0.0.2/24 for the other internship task
- Re-ran Nmap -p- over the direct link: 22/80/443 open, 65,532 closed
- Ran Nikto over HTTP and HTTPS: /backup/ directory indexing, missing security headers, banner disclosure, cert CN mismatch
- Confirmed db-dump.sql.bak is publicly downloadable (HTTP 200, no auth)
- Captured webroot permissions and server access-log source-IP counts
- Hashed the full evidence folder and copied it to the host
- Wrote baseline-assessment-report.md (evidence phase)

### Decisions
- Kept SSH unweakened to limit the planted misconfigurations
- Skipped a targeted weak-password test on testuser; the report states that scanners did not detect it
- Used the host-only link for all scans and kept the NAT-path results as preliminary evidence only

## 2026-11-03
- Updated scope.md to v1.1 (fictional company named Kilele Traders Ltd, Kali address confirmed, NAT-path artifact disclosed, Lynis metric added, baseline described as the author's own checklist modelled on CIS, references added)
- Updated the asset inventory (services and ports, installed software, finding origin table: planted vs pre-existing)
- Built risk-register.md from checks-before.txt: 11 findings (F-01 to F-11), rated by Likelihood x Impact
- Drafted remediation-plan.md (change, validation and rollback for each finding)
- Created the dated evidence folder `~/baseline-lab/evidence/2026-11-03/` on apache-web-01
- **F-01 (exposed backup):** db-dump.sql.bak was 0 bytes (ls -l); deleted `public_html/backup`; from Kali, `/backup/` and the dump now return 404 (`~/f01-validation.txt` on Kali)
- **F-02 (world-writable web root):** before: `public_html` and `index.html` (w4-before.txt); applied chown www-data, directories 750, files 640; after: 0 world-writable paths (w4-after.txt); site returns 200 from Kali
- **F-03 (testuser):** `id testuser` showed only its own group (testuser-id-before.txt); testuser was denied access to `/var/www/apache-web-01` (750 www-data:www-data, testuser-parent-access.txt; testuser-webroot-access.txt was taken after F-02 was applied, so it does not show the baseline and is not used as evidence); removed the account; `getent passwd testuser` returns nothing; accounts with UID 1000 or higher are nobody, marshel, splunkfwd (a3-after.txt)
- **F-04 (SSH password login):** installed an ed25519 key for marshel from Kali and from the Windows host; added `/etc/ssh/sshd_config.d/00-hardening.conf` (PasswordAuthentication no); the first Kali test still accepted a password because the daemon had not re-read its config; ran `sudo systemctl reload ssh`; re-test from Kali: forced password login gives `Permission denied (publickey)` and key login works (ssh-after.txt on apache-web-01, `~/f04-validation.txt` on Kali)
- **F-05 (firewall):** the allow rules for 22, 80 and 443 already existed (the planted fault was UFW switched off); set default deny incoming and enabled UFW (ufw-after.txt); quick Nmap from Kali: 22, 80, 443 open, 21, 25, 3306 and 8080 filtered (`~/nmap-after-ufw.txt` on Kali)
- **F-06 (updates):** 182 updates available before (131 security, per the login banner); ran apt update and apt upgrade; rebooted; kernel went from 7.0.0-30 to 7.0.0-42-generic (Ubuntu 26.04.1); 0 updates reported at login; two helper packages still listed as upgradable (python3-software-properties, software-properties-common), probably phased rollout; UFW, apache2 and ssh active after reboot; site returns 200 (upgradable-after.txt)
- Reviewed baseline-assessment-report.md against the new evidence; corrections to make: SSH is no longer described as out of scope, `index.html` is also world-writable (the 777 note said directory only), findings table updated to match the register, update counts explained (11 on 10-28 from a stale index, 176 on 10-29, 182 on 11-03), 16-control result added

### Decisions (2026-11-03)
- Fixed findings in ID order, with F-06 (updates and reboot) before the Apache configuration fixes so the upgrade would not clash with edited config files
- Lowered F-02 from High to Medium after finding that testuser could not reach the web root (parent folder 750, no www-data or sudo group membership); the control still counts as failed in the baseline (6 of 16)
- Left the two phased packages as a documented residual risk instead of forcing them
- Created SSH keys for Kali and Windows before disabling password login, to avoid a lockout; both keys have empty passphrases (acceptable in an isolated lab, recorded as a limitation)
- Treated the empty db-dump.sql.bak as a real exposure of a file that looks like a backup, not as exposure of data, and set data sensitivity back to Medium
- Added the security headers through a new config file (no existing files edited) and set HSTS to a short lifetime because of the self-signed certificate

### Still to log when done
- F-07 (fail2ban), F-08 (directory listing), F-09 (version banners), F-10 (security headers), F-11 (certificate)
- After-state checks: checks-after.txt, Lynis, Nmap -p-, Nikto
- Evidence hashes and copy to the Windows host, snapshot apache-web-01-REMEDIATED-final
- Final report, README, commit and push