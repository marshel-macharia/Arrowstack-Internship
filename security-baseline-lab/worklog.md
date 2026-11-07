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

## 2026-11-05
- Created the evidence folder `~/baseline-lab/evidence/2026-11-05/` on apache-web-01 (the first save attempts failed because the folder did not exist yet)
- **F-07 (fail2ban):** installed fail2ban and added the drop-in `/etc/fail2ban/jail.d/sshd-local.conf` (maxretry 3, findtime 10m, bantime 1h, aggressive mode, Windows host in ignoreip). The first test of 4 bad logins from Kali did not ban anything: `fail2ban-client get` showed maxretry 5 and bantime 600, the packaged defaults, because fail2ban had not been restarted. After `systemctl restart fail2ban` the values read 3 and 3600, and 4 bad logins banned 192.168.208.30 (Total banned 1). Released Kali with `unbanip` (evidence: sshd-local.conf, f07-ban-log.txt, f07-after.txt)
- **F-09 (version banners):** found the settings with `grep -rniE` (ServerTokens Full at line 13 and ServerSignature On at line 23 of conf-available/security.conf); set ServerTokens Prod and ServerSignature Off. From Kali the Server header is `Apache` with no version and the 404 page has no signature footer (security.conf.before and .after, `f08-after.txt` on Kali)
- **F-08 (directory listing):** `Options +Indexes` was at line 8 of sites-available/apache-web-01.conf; changed it to `-Indexes`. `apache2ctl configtest` printed Syntax OK and Apache was reloaded. A temporary test folder with no index file returned 200 before and 403 after (`f09-before.txt` on the server, `f09-after.txt` on Kali); folder removed. Left the autoindex module loaded
- **F-10 (security headers):** enabled mod_headers and added `conf-available/security-headers.conf` (X-Content-Type-Options, Referrer-Policy, Permissions-Policy, Content-Security-Policy with frame-ancestors, HSTS on HTTPS only), enabled it with a2enconf and restarted Apache. Before: none of the headers (`f10-before.txt`); after: four on HTTP and five on HTTPS (`f10-after.txt`)
- Copied the fix evidence from apache-web-01 and Kali to the Windows host (`evidence/2026-11-05` and `evidence/2026-11-05-kali`)
- Took snapshot `apache-web-01-HARDENED-after-remediation` (11:23 local, VM powered off), then powered the server on again for the re-test. The reboot doubled as a persistence test
- **After-run checks:** recreated the 16 checks as `run-checks.sh` from the layout of checks-before.txt and ran it into `checks-after.txt`: A3, S2, F1, W1, W2, W4, W5 and L2 now pass, so the firewall, fail2ban, SSH setting and Apache banner survived the reboot. W3 still shows the autoindex module. M2 listed 12 upgradable packages, including three newly published security updates (apt, libapt-pkg7.0, python3-twisted); kept that run as `checks-after-pre-update.txt`
- Ran `apt update && apt upgrade` again (no reboot needed) and reran the checks. 9 non-security packages remained at that point (base-files, motd-news-config, the software-properties pair, the vim family, xxd); `apt upgrade -s` reports "Not upgrading yet due to phasing" (`m2-phasing-check.txt`)
- **Lynis after:** hardening index 69 (baseline 61), 264 tests, 0 warnings (baseline 1), 48 suggestions (baseline 49); `sudo ss -tulpn` shows only 22, 80 and 443 plus local services
- **Nmap after (from Kali):** `-p- -T4 --max-retries 1` found 22, 80 and 443 open and 65,532 filtered (89 s); service detection shows Apache httpd with no version and OpenSSH 10.2p1 Ubuntu 2ubuntu3.8; fail2ban did not ban Kali during the scans
- **Nikto after:** no /backup/ listing, no version banner, headers present; remaining items: certificate CN mismatch, HSTS flagged on HTTP only, X-Frame-Options deprecation note, allowed methods, and X-Content-Type-Options "not set" on both ports. Checked that header with a GET, a 404, an OPTIONS and an HTTPS request: it is present each time (`f10-xcto-verification.txt`)
- Result: checklist **15 of 16** (W3 still fails), up from 6 of 16
- Updated the documents: scope-statement.md v1.2, baseline-assessment-report.md v1.1 (applied the corrections listed on 2026-11-03), risk-register.md v2.0, remediation-plan.md v2.0, and wrote final-security-report.md

### Decisions (2026-11-05)
- Kept the autoindex module loaded because `Options -Indexes` already blocks listings (403 test); W3 stays a fail and the risk is accepted as R-1 (Low)
- Scored M2 as a pass on the security-update criterion: the register worded it "no pending updates", but non-security updates are deferred by phasing, in line with the 2026-11-03 decision not to force phased packages. Both scores are reported: 15 of 16, or 14 of 16 under the original wording. The change of wording is disclosed in scope-statement.md section 9 (updated on 2026-11-06 after the recheck below)
- Accepted F-11 (self-signed certificate) for the lab; not fixed
- Set HSTS to max-age=31536000 on HTTPS only. This replaces the 2026-11-03 plan of a short lifetime; in this lab browsers ignore HSTS on invalid certificates and bare IP addresses, so the difference has no practical effect
- Treated Nikto's X-Content-Type-Options finding as a false positive after the four-request check; the cause was not determined
- Used `--max-retries 1` for the full-port Nmap scan, because the firewall now drops packets to closed ports; disclosed as a difference from the baseline scan
- The checklist script was reconstructed from the baseline output; disclosed as a limitation
- Renamed the two after-run evidence folders to `-after-server` and `-after-kali` so they do not overwrite each other on the Windows host. The Kali files `f08-after.txt` (banner, F-09) and `f09-*.txt` (directory listing, F-08) keep their working-order names so the SHA-256 hashes still match; a note in the register, plan and report explains the mapping

## 2026-11-06
- Wrote the README and updated this work log
- **M2 recheck:** after `apt update`, 11 packages were upgradable, not zero. New since the last upgrade: the Ubuntu security update `ca-certificates`; `base-files` and `motd-news-config` had become installable; `wazuh-agent` 4.14.10 was offered from Wazuh's own repository; 7 packages were still phased. The rest of the checklist was unchanged about 20 hours later: the diff against `checks-after.txt` showed only the W5 `Date:` line and the M2 section. Saved as `m2-recheck-2026-11-06-before.txt` and `checks-after-2026-11-06-before-install.txt`
- Ran `sudo apt install --only-upgrade ca-certificates base-files motd-news-config` (no reboot needed). Result: no Ubuntu security updates pending; 8 packages still listed: the 7 phased ones plus `wazuh-agent` (`m2-recheck-2026-11-06-after.txt`). Reran the checklist into `checks-after-final.txt`
- Updated the scope statement, risk register, remediation plan, final report and README with the new M2 wording and evidence files

### Decisions (2026-11-06)
- M2 stays scored as a pass on the security-update criterion (15 of 16), with the strict wording ("no pending updates") reported as 14 of 16. It was not claimed as 15 of 16 on the strict wording, because 7 phased packages and one third-party package are still pending
- Did not force the 7 phased packages, in line with the 2026-11-03 decision
- Did not update `wazuh-agent`: it is outside the assessment, and a Wazuh agent must not be newer than its manager (the manager version has not been checked)
- The scans (Lynis, Nmap, Nikto) ran before these last updates; the packages installed afterwards (a certificate bundle and two small base packages) do not affect their results

### Still to do
- Regenerate the hash file in the after-server folder without the old hash file in place (`rm -f sha256-after-server.txt` first), since `sha256sum * > file` hashes an existing hash file as empty and the check on Windows would fail; do the same for the Kali folder if it was regenerated
- Rename the after-run folders (if not done), copy them to the Windows host and verify all hashes
- Check that the F-01 origin in the register (planted, file created 2026-10-28 07:46 UTC) matches what I did
- Save the updated documents into the repo (the baseline report keeps its name, `baseline-assessment-report.md`), remove `testuser` from the asset inventory, add `.gitattributes` with `evidence/** -text`
- Take a final snapshot of apache-web-01. The 2026-11-05 snapshot predates both patching rounds after it
- Commit and push