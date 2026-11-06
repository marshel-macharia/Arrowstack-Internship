# Remediation Plan: apache-web-01

**Project:** Security Baseline Assessment Lab (Arrowstack Cyber Security Internship, Project 1)
**Author:** Marshel Mburu Macharia
**Date:** 2026-11-06
**Version:** 2.0 (fixes applied and validated; v1.0 of 2026-11-03 was the draft plan)
**Source:** risk-register.md (F-01 to F-11)

## Result in one line
10 of 11 findings were fixed or mitigated and 1 (F-11) was accepted. The checklist went from 6 of 16 passing to 15 of 16. Fixes F-01 to F-06 were applied on 2026-11-03 and F-07 to F-10 on 2026-11-05, in the planned order.

## Principles
- Fix in ID order: High first (F-01 to F-04), then Medium, then Low.
- Each fix has a change, a validation (re-test of the check that failed) and a rollback.
- Every change gets a line in worklog.md and its output saved in a dated evidence folder.
- Rollback for everything: snapshot `apache-web-01-UNHARDENED-baseline`. New evidence was copied to the Windows host first, because restoring a snapshot discards files created on the VM after it.
- Lockout risk: F-04 (SSH) and F-05 (firewall). A second SSH session was kept open while applying them.
- F-06 (updates) came before the Apache configuration fixes (F-08 to F-10) so the upgrade did not clash with the edited config files.
- Evidence folders: `2026-11-03` (F-01 to F-06), `2026-11-05` and `2026-11-05-kali` (F-07 to F-10), `2026-11-05-after-server` and `2026-11-05-after-kali` (re-test).
- File names: `f08-after.txt` belongs to the banner finding (F-09), and `f09-before.txt` and `f09-after.txt` belong to the directory listing finding (F-08). They were named in the working order of the fixes and were not renamed, so the SHA-256 hashes still match.

## F-01 (High): exposed /backup/ and db-dump.sql.bak — applied 2026-11-03
**Planned:** find and delete the directory and the dump.
**Applied:** the `backup` directory (with the 0-byte dump) was deleted from the web root. The file was simulated, so no credentials needed rotating.

**Validation (from Kali):** `/backup/` and `/backup/db-dump.sql.bak` both return 404 over HTTP and HTTPS (`f01-validation.txt`). Nikto after shows no /backup/ finding.
**Rollback:** snapshot only. The file is deliberately not restored.
**Evidence:** `f01-validation.txt`, `nikto-after-http.txt`, `nikto-after-https.txt`; baseline: `db-dump-headers.txt`, `backup-listing-http.html`

## F-02 (Medium, re-rated from High): world-writable web root — applied 2026-11-03
**Planned and applied:** owner `www-data:www-data`, directories 750, files 640 under `public_html`.

**Validation:** `find /var/www -perm -0002 ! -type l` returned two paths before (`w4-before.txt`) and nothing after (`w4-after.txt`); the site still returns 200 from Kali.
**Rollback:** `chmod 777` on the directory (not recommended; for reference only).
**Evidence:** `w4-before.txt`, `w4-after.txt`, `testuser-parent-access.txt`

## F-03 (High): unauthorized account testuser — applied 2026-11-03
**Planned and applied:** the account's groups were recorded first (no sudo or www-data rights), then the account and its home directory were removed.

**Validation:** `getent passwd testuser` returns nothing; regular accounts are `nobody`, `marshel` and `splunkfwd` (`a3-after.txt`, `checks-after.txt` A3).
**Rollback:** recreate the account only if needed for a re-test.
**Evidence:** `testuser-parent-access.txt`, `a3-after.txt`

## F-04 (High): SSH password authentication — applied 2026-11-03
**Applied:** key pairs for Kali and the Windows host were installed for `marshel` (`ssh-copy-id`), and key login was confirmed. Then `/etc/ssh/sshd_config.d/00-hardening.conf` set `PasswordAuthentication no`, with a syntax check (`sshd -t`).

**Deviation from the plan:** the plan assumed new connections would read the new setting straight away. In practice the first test still accepted a password, and the setting only took effect after `systemctl reload ssh`.

**Validation (from Kali):** a forced password login returns `Permission denied (publickey)` (`f04-validation.txt`). `sshd -T` shows `passwordauthentication no` and `permitrootlogin prohibit-password`, and the setting survived a reboot (`checks-after.txt`, S1/S2).
**Rollback:** remove `/etc/ssh/sshd_config.d/00-hardening.conf` and reload ssh.
**Evidence:** `ssh-after.txt`, `f04-validation.txt`, `checks-after.txt`

## F-05 (Medium): firewall inactive — applied 2026-11-03
**Applied:** `ufw default deny incoming`, `ufw default allow outgoing`, rules for 22, 80 and 443 (they already existed), then `ufw enable`.

**Validation:** `ufw status` is active (`ufw-after.txt`). A Kali scan of seven common ports shows only 22, 80 and 443 open (`nmap-after-ufw.txt`). A full-port scan after the reboot shows the same three open and 65,532 filtered (`nmap-after-full.txt`).
**Rollback:** `sudo ufw disable`.
**Evidence:** `ufw-after.txt`, `nmap-after-ufw.txt`, `nmap-after-full.txt`

## F-06 (Medium): pending updates — applied 2026-11-03, 2026-11-05 and 2026-11-06
**Applied:** on 2026-11-03, `apt update`, a full upgrade and a reboot (kernel 7.0.0-30 to 7.0.0-42). On 2026-11-05, after the reboot test, the checklist showed 12 upgradable packages including three newly published security updates (`apt`, `libapt-pkg7.0`, `python3-twisted`), so `apt update && apt upgrade` was run again (no reboot needed). A final recheck on 2026-11-06 found further updates, including the Ubuntu security update `ca-certificates`; `sudo apt install --only-upgrade ca-certificates base-files motd-news-config` installed them (no reboot needed).

**Validation:** after the 2026-11-06 install, no Ubuntu security updates are pending. 7 non-security packages (`software-properties` pair, `vim` family, `xxd`) are held back by Ubuntu's phased rollout: `apt upgrade -s` reports "Not upgrading yet due to phasing". One more update, `wazuh-agent` 4.14.10, comes from Wazuh's own repository; it was left alone because it is outside the assessment and a Wazuh agent must not be newer than its manager (`m2-recheck-2026-11-06-after.txt`). The phased packages were not forced, in line with the 2026-11-03 decision. Lynis no longer raises warning PKGS-7392.
**Rollback:** snapshot only.
**Evidence:** `upgradable-before.txt`, `upgradable-after.txt`, `checks-after-pre-update.txt`, `checks-after.txt` (M2), `m2-phasing-check.txt`, `m2-recheck-2026-11-06-before.txt`, `m2-recheck-2026-11-06-after.txt`, `checks-after-2026-11-06-before-install.txt`, `checks-after-final.txt`

## F-07 (Medium): fail2ban not active — applied 2026-11-05
**Planned:** install fail2ban and use its default sshd jail.
**Applied:** fail2ban installed, plus a drop-in `/etc/fail2ban/jail.d/sshd-local.conf`: `enabled = true`, `backend = systemd`, `maxretry = 3`, `findtime = 10m`, `bantime = 1h`, `mode = aggressive`, with the Windows host in `ignoreip`.

**Deviation from the plan:** the packaged defaults (5 attempts, 10 minutes) did not ban the 4-attempt test, and the drop-in only took effect after `systemctl restart fail2ban`.

**Validation:** settings read 3 and 3600 after the restart. Four failed logins from Kali banned 192.168.208.30 (`Total banned: 1`), and the ban was then lifted. The fail2ban log records the Found, Ban and Unban events. L2 passes after a reboot.
**Rollback:** `sudo apt remove fail2ban`.
**Evidence:** `sshd-local.conf`, `f07-ban-log.txt`, `f07-after.txt`

## F-08 (Medium): directory listing — applied 2026-11-05
**Planned:** change `Options +Indexes` to `-Indexes` and disable the autoindex module.
**Applied:** `Options -Indexes` in `/etc/apache2/sites-available/apache-web-01.conf` (line 8), then `apache2ctl configtest` (Syntax OK) and a reload. **The autoindex module was deliberately left loaded**, so check W3 still fails.

**Validation:** a temporary folder with no index file returned 200 before (`f09-before.txt`) and 403 after (`f09-after.txt`); the folder was then removed.
**Rollback:** set `Options +Indexes` again and reload.
**Evidence:** `apache-web-01.conf.before`, `apache-web-01.conf.after`, `f09-before.txt`, `f09-after.txt`

## F-09 (Low): version banners — applied 2026-11-05
**Planned and applied:** `ServerTokens Prod` and `ServerSignature Off` in `/etc/apache2/conf-available/security.conf` (lines 13 and 23), then `configtest` and a reload.

**Validation (from Kali):** the Server header is `Apache` with no version or OS; the 404 page has no "Server at ... Port 80" footer (`f08-after.txt`); Nmap service detection reports "Apache httpd" with no version (`nmap-after-sv-web.txt`).
**Rollback:** set the old values back.
**Evidence:** `security.conf.before`, `security.conf.after`, `f08-after.txt`, `nmap-after-sv-web.txt`

## F-10 (Low): missing security headers — applied 2026-11-05
**Planned:** add five headers to the HTTPS vhost or `security.conf`, with HSTS at `max-age=300`.
**Applied:** `mod_headers` enabled and a separate file `/etc/apache2/conf-available/security-headers.conf` enabled with `a2enconf`: `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy` (geolocation, microphone, camera off), `Content-Security-Policy: default-src 'self'; frame-ancestors 'none'`, and `Strict-Transport-Security: max-age=31536000` on HTTPS only. Apache was restarted, because a newly enabled module needs a restart rather than a reload.

**Deviation from the plan:** HSTS was set to one year, not 5 minutes. In this lab the practical effect is nil: browsers ignore HSTS on connections with certificate errors and for bare IP addresses. If the site is later opened in a browser by name with this self-signed certificate, reduce the value first. A strict CSP can break pages that use inline scripts or external resources; it suits this simple site.

**Validation (from Kali):** HTTP returned none of the headers before and four after; HTTPS returns all five (`f10-before.txt`, `f10-after.txt`). The X-Content-Type-Options header was verified on a GET, a 404 page, an OPTIONS request and HTTPS (`f10-xcto-verification.txt`). Nikto still reports that header as "not set"; this is treated as a scanner false positive.
**Rollback:** `a2disconf security-headers` and reload.
**Evidence:** `f10-before.txt`, `f10-after.txt`, `security-headers.conf`, `f10-xcto-verification.txt`

## F-11 (Low): self-signed certificate, CN mismatch, no SAN — not applied (accepted)
**Planned:** reissue the certificate with a SAN, or accept the risk with a written reason.
**Decision:** accepted, as a lab environment with a self-signed certificate. Nikto after still reports the CN mismatch (`nikto-after-https.txt`). A production system would use a certificate from a trusted CA.

## Validation after all fixes (2026-11-05)
1. The checklist was run again after a reboot with `run-checks.sh` (reconstructed from the baseline output): `checks-after.txt` shows **15 of 16 passing** (W3 fails; see scope-statement.md section 9 for the M2 wording). The earlier run before the second patching round is kept as `checks-after-pre-update.txt`. A recheck on 2026-11-06, about 20 hours later and before the new updates were installed, differed from it only in the `Date:` line and the M2 section (`checks-after-2026-11-06-before-install.txt`); the final run is `checks-after-final.txt`. The reboot confirmed that the firewall, fail2ban, SSH and Apache settings persist.
2. Lynis: hardening index **69** (baseline 61), 264 tests, 0 warnings (baseline 1), 48 suggestions (baseline 49).
3. From Kali over the host-only link: full-port Nmap (22, 80, 443 open; 65,532 filtered; `--max-retries 1` was used), service detection, and Nikto over HTTP and HTTPS.
4. Evidence folders are hashed with SHA-256 and copied to the Windows host.
5. Snapshot `apache-web-01-HARDENED-after-remediation` taken on 2026-11-05 before the re-test. The plan named it `apache-web-01-REMEDIATED-final`.
6. The Status and Re-test result columns of risk-register.md are updated, and the before/after comparison is in `final-security-report.md`.

## Accepted residual risks
- F-08 / R-1: the autoindex module stays loaded (listing is blocked by `-Indexes`).
- F-11 / R-2: the certificate remains self-signed.
- R-3: 7 non-security updates are deferred by phasing, a third-party `wazuh-agent` update was left alone, and patching is a recurring task (new security updates appeared on 2026-11-03 and 2026-11-06).
- R-4 to R-6: SSH version string, no HTTP to HTTPS redirect, generic Lynis suggestions (see risk-register.md).
- F-03: the `testuser` password was never tested directly; the account is removed.