# Risk Register: Kilele Traders Ltd (fictional), apache-web-01

**Project:** Security Baseline Assessment Lab (Arrowstack Cyber Security Internship, Project 1)
**Author:** Marshel Mburu Macharia
**Date:** 2026-11-06
**Version:** 2.0 (after remediation and re-test; v1.0 was the baseline register of 2026-11-03)
**Asset:** A-01 apache-web-01 (192.168.208.10)

## Rating method
- **Likelihood (L):** how likely the weakness is to be abused on a public-facing web server. 1 = unlikely, 2 = possible, 3 = likely.
- **Impact (I):** the consequence if it is abused. 1 = minor, 2 = moderate, 3 = severe (data exposure or loss of control of the site or server).
- **Score = L x I.** 1-2 Low, 3-4 Medium, 6-9 High (as defined in scope-statement.md).
- **Order:** the IDs keep the v1.0 order. F-02 was re-rated in v2.0 (see below), so the table is no longer strictly sorted by score.
- **Origin:** Planted means introduced on 2026-10-28 to simulate a poorly configured server. Pre-existing means present in the original build.

## Summary
11 findings: 3 High, 5 Medium, 3 Low (v1.0 had 4 High, 4 Medium, 3 Low; the change is the re-rating of F-02). Ten come from the 16-control checklist and one (F-11) comes from Nikto.

Result after remediation and re-test (2026-11-05, with a final update recheck on 2026-11-06): all 3 High findings and 4 of 5 Medium findings closed; F-08 mitigated; F-11 accepted. The checklist went from 6 of 16 passing (37.5%) to 15 of 16 (93.75%). Only W3 (autoindex module) still fails. See scope-statement.md section 9 for the wording of M2.

## Register
| ID | Control | Finding | Origin | L | I | Score | Severity | Evidence | Fix applied (summary) | Status | Re-test result |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F-01 | W2 | /backup/ is publicly browsable and db-dump.sql.bak can be downloaded without authentication (HTTP 200). The file was empty (0 bytes), so no data was exposed; the rating reflects what a real backup in that place would expose | Planted (file created 2026-10-28 07:46 UTC, between the two snapshots) | 3 | 3 | 9 | High | checks-before.txt (W2); db-dump-headers.txt; db-dump-size.txt; backup-listing files; nikto-http.txt.txt | Removed the /backup/ directory and the dump from the web root | Closed (2026-11-03) | Both URLs return 404 from Kali (f01-validation.txt); no /backup/ finding in Nikto after (nikto-after-http.txt, nikto-after-https.txt). W2 passes |
| F-02 | W4 | Web root is world-writable: public_html and public_html/index.html. The parent directory (750, www-data) stopped other local users from reaching it, which is why L was lowered from 2 to 1 | Planted (public_html); index.html cause not determined | 1 | 3 | 3 | Medium | checks-before.txt (W4); webroot-perms-before.txt; w4-before.txt; testuser-parent-access.txt | Owner www-data, directories 750, files 640 | Closed (2026-11-03) | w4-after.txt is empty; site still returns 200. W4 passes |
| F-03 | A3 | Unauthorized local account `testuser` with a weak password | Planted | 3 | 2 | 6 | High | checks-before.txt (A3); asset inventory; testuser-parent-access.txt. Password not tested directly (recorded decision) | Account removed | Closed (2026-11-03) | `getent passwd testuser` returns nothing; regular accounts are nobody, marshel, splunkfwd (a3-after.txt). A3 passes |
| F-04 | S2 | SSH password authentication is enabled (PermitRootLogin is correctly prohibit-password) | Pre-existing | 3 | 2 | 6 | High | checks-before.txt (S1/S2) | Key login set up first, then PasswordAuthentication no in /etc/ssh/sshd_config.d/00-hardening.conf and a reload of ssh | Closed (2026-11-03) | Forced password login from Kali: Permission denied (publickey) (f04-validation.txt); `sshd -T` shows passwordauthentication no, still true after a reboot (ssh-after.txt, checks-after.txt). S2 passes |
| F-05 | F1 | Host firewall (UFW) is inactive | Planted | 2 | 2 | 4 | Medium | checks-before.txt (F1) | Default deny incoming, allow 22, 80 and 443, enabled | Closed (2026-11-03) | UFW active (ufw-after.txt); Nmap shows 22, 80, 443 open and the other 65,532 ports filtered (nmap-after-ufw.txt, nmap-after-full.txt). F1 and F2 pass |
| F-06 | M2 | Pending package updates, including security updates for openssl and libssl3t64 | Pre-existing | 2 | 2 | 4 | Medium | checks-before.txt (M2, 11 packages); upgradable-before.txt (176 packages, 124 security); lynis-before.txt (PKGS-7392) | Full upgrade and reboot on 2026-11-03; a second upgrade on 2026-11-05 installed three newly published security updates | Closed (2026-11-06) | A recheck on 2026-11-06 found new updates, including the Ubuntu security update `ca-certificates`; after installing the Ubuntu ones, no Ubuntu security updates were pending. 7 non-security packages remain held back by phased rollout, and the third-party `wazuh-agent` update was left alone (m2-recheck-2026-11-06-before.txt, m2-recheck-2026-11-06-after.txt, checks-after-final.txt). Lynis warning PKGS-7392 no longer raised. M2 scored as pass on the security-update criterion (see scope-statement.md section 9) |
| F-07 | L2 | fail2ban is not active, so SSH login attempts are not throttled | Pre-existing | 2 | 2 | 4 | Medium | checks-before.txt (L2) | fail2ban installed; sshd jail drop-in with maxretry 3, findtime 10m, bantime 1h, aggressive mode | Closed (2026-11-05) | The packaged defaults (5 attempts, 10 minutes) did not ban a 4-attempt test. After the drop-in and a restart, 4 failed logins from Kali banned 192.168.208.30 (f07-ban-log.txt, f07-after.txt). L2 passes after a reboot |
| F-08 | W3 | Directory listing: autoindex module loaded and Indexes enabled on the web root | Planted | 3 | 1 | 3 | Medium | checks-before.txt (W3); dirlisting-http.html; dirlisting-https.html | `Options +Indexes` changed to `Options -Indexes`. The autoindex module was left loaded | Mitigated (2026-11-05) | A temporary folder with no index file returned 200 before and 403 after (f09-before.txt, f09-after.txt). W3 still fails because the module is loaded; accepted as a Low residual risk (R-1) |
| F-09 | W1 | Version banners exposed: ServerTokens Full, ServerSignature On | Planted | 2 | 1 | 2 | Low | checks-before.txt (W1); headers-http.txt; 404-signature-check.txt | ServerTokens Prod and ServerSignature Off in security.conf | Closed (2026-11-05) | Server header is "Apache" with no version; the 404 page has no signature footer; Nmap reports "Apache httpd" with no version (f08-after.txt, nmap-after-sv-web.txt). W1 passes |
| F-10 | W5 | Security headers missing on HTTPS: CSP, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, HSTS | Pre-existing | 2 | 1 | 2 | Low | checks-before.txt (W5); nikto-https.txt.txt | mod_headers enabled; security-headers.conf adds the headers (HSTS on HTTPS only) | Closed (2026-11-05) | HTTP returns four headers, HTTPS all five (f10-before.txt, f10-after.txt). W5 passes. Nikto still reports X-Content-Type-Options as "not set", but the header is present on GET, 404, OPTIONS and HTTPS responses (f10-xcto-verification.txt), so this is treated as a scanner false positive |
| F-11 | none (Nikto) | Self-signed certificate with CN mismatch and no SAN | Pre-existing | 2 | 1 | 2 | Low | nikto-https.txt.txt; Nmap service scan | None. Accepted for the lab | Accepted (2026-11-05) | Nikto after still reports the CN mismatch (nikto-after-https.txt). Residual risk R-2 |

**Evidence file names.** The Kali files `f08-after.txt` and `f09-*.txt` were named in the working order of the fixes. `f08-after.txt` belongs to the banner finding (F-09) and `f09-before.txt` and `f09-after.txt` belong to the directory listing finding (F-08). The names were not changed, so the SHA-256 hashes still match.

## How the 16 controls map to findings
| Control | Check | Baseline result | After result | Finding |
|---|---|---|---|---|
| A1 | Only root has UID 0 | Pass | Pass | |
| A2 | No empty passwords | Pass | Pass | |
| A3 | Regular accounts are authorized | Fail | Pass | F-03 |
| S1 | Root cannot log in with a password over SSH | Pass | Pass | |
| S2 | SSH password authentication disabled | Fail | Pass | F-04 |
| F1 | Firewall active | Fail | Pass | F-05 |
| F2 | Only expected ports listening (22, 80, 443) | Pass | Pass | |
| W1 | Version banners suppressed | Fail | Pass | F-09 |
| W2 | /backup/ not publicly accessible | Fail | Pass | F-01 |
| W3 | autoindex module disabled | Fail | **Fail** | F-08 |
| W4 | No world-writable files in the web root | Fail | Pass | F-02 |
| W5 | Security headers present | Fail | Pass | F-10 |
| M1 | Unattended upgrades enabled | Pass | Pass | |
| M2 | No pending (security) updates | Fail | Pass | F-06 |
| L1 | rsyslog active | Pass | Pass | |
| L2 | fail2ban active | Fail | Pass | F-07 |

Baseline: 6 of 16 passing (37.5%). After: 15 of 16 passing (93.75%). Under the original strict wording of M2 ("no pending updates"), 14 of 16 (87.5%).

## Attack chain
Before remediation, F-04, F-03 and F-02 looked as if they combined: SSH accepted passwords (F-04), `testuser` had a weak password (F-03) and the web root was world-writable (F-02). The 2026-11-03 checks showed that `testuser` could not enter /var/www/apache-web-01 (750, owner www-data) and had no sudo or www-data rights, so the step through F-02 was not available to that account. That is why F-02 was re-rated to likelihood 1 and why the impact of F-03 stayed at 2. F-04 and F-03 on their own were still a real risk: F-07 meant nothing slowed password guessing down, and F-08 helped an attacker find F-01.

After remediation the chain is broken at F-04 (key-only login), F-03 (account removed) and F-07 (lockout after repeated failures).

## Accepted residual risks
| ID | Residual risk | Rating | Decision |
|---|---|---|---|
| R-1 | The autoindex module is still loaded (F-08). Listing is blocked by `Options -Indexes` and verified with a 403 test. A future `Options +Indexes` or a permitted .htaccess could switch listings back on | Low | Accepted. Optional hardening: `a2dismod autoindex` |
| R-2 | Self-signed certificate with CN mismatch and no SAN (F-11) | Low | Accepted for the lab. A production system would use a certificate from a trusted CA |
| R-3 | 7 non-security packages are held back by phased rollout, and a `wazuh-agent` update from a third-party repository was left alone (an agent must not be newer than its manager; it is outside the assessment scope). New updates appear regularly: three new security updates appeared within two days of the first patching round, and another (`ca-certificates`) on 2026-11-06 | Low | Accepted. Check weekly; unattended-upgrades is enabled (M1) |
| R-4 | SSH reports its exact version (OpenSSH 10.2p1 Ubuntu 2ubuntu3.8). This is default OpenSSH behaviour and the version is current | Low | Accepted |
| R-5 | HSTS is sent on HTTPS only, by design (browsers ignore it on HTTP), and there is no HTTP to HTTPS redirect. Nikto flags HSTS on port 80 for this reason | Low | Accepted. A redirect is an optional improvement |
| R-6 | Lynis still lists 48 generic hardening suggestions (password aging, auditd, ModSecurity, separate partitions and others), mostly outside this project's scope | Low | Accepted. Candidates for a later hardening phase |

## Open points from v1.0, resolved
1. **Update count:** checks-before.txt (2026-10-28) lists 11 upgradable packages, while upgradable-before.txt (2026-10-29) lists 176 (124 security), and the server's login message on 2026-11-03 showed 182 (131 security). The most likely cause of the low first number is that the package index had not been refreshed. The report uses the 2026-10-29 figures.
2. **index.html permissions:** W4 lists index.html as world-writable, so the baseline note that only the directory was 777 applies to public_html, backup/ and the dump only. Both public_html and index.html were fixed (w4-after.txt is empty). The cause of the index.html permission was not determined.
3. **testuser privileges:** the account had no sudo or www-data rights, so the impact of F-03 stays at 2 and its score at 6 (testuser-parent-access.txt).
4. **F-01 origin:** Planted. The dump was created on 2026-10-28 at 07:46 UTC, after the HARDENED-final snapshot (10:05 local) and before the UNHARDENED-baseline snapshot (11:02 local).
5. **Ratings are judgment calls:** F-06 was kept at Medium. It would have been High if a pending update had fixed a remotely exploitable flaw that was actively reachable; none was identified.