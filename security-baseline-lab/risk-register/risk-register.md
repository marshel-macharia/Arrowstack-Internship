# Risk Register: Kilele Traders Ltd (fictional), apache-web-01

**Project:** Security Baseline Assessment Lab (Arrowstack Cyber Security Internship, Project 1)
**Author:** Marshel Mburu Macharia
**Date:** 2026-11-03
**Version:** 1.0
**Asset:** A-01 apache-web-01 (192.168.208.10)

## Rating method
- **Likelihood (L):** how likely the weakness is to be abused on a public-facing web server. 1 = unlikely, 2 = possible, 3 = likely.
- **Impact (I):** the consequence if it is abused. 1 = minor, 2 = moderate, 3 = severe (data exposure or loss of control of the site or server).
- **Score = L x I.** 1-2 Low, 3-4 Medium, 6-9 High (as defined in scope.md).
- **Order:** by score, then higher impact first, then checklist order.
- **Origin:** Planted means introduced on 2026-10-28 to simulate a poorly configured server. Pre-existing means present in the original build.

## Summary
11 findings: 4 High, 4 Medium, 3 Low. Ten come from the 16-control checklist (6 pass, 10 fail, 37.5% passing) and one (F-11) comes from Nikto.

## Register
| ID | Control | Finding | Origin | L | I | Score | Severity | Evidence | Planned fix (summary) | Status | Re-test result |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F-01 | W2 | /backup/ is publicly browsable and db-dump.sql.bak can be downloaded without authentication (HTTP 200). The file was empty (0 bytes), so no data was exposed; the rating reflects what a real backup in that place would expose | [confirm: planted or pre-existing] | 3 | 3 | 9 | High | checks-before.txt (W2); db-dump-headers.txt; db-dump-size.txt; backup-listing files; nikto-http.txt.txt | Remove the file and the /backup/ directory from the web root, keep backups off the server, rotate any credentials the dump contained | Open | Pending |
| F-02 | W4 | Web root is world-writable: public_html and public_html/index.html | Planted (public_html); [confirm] for index.html | 2 | 3 | 6 | High | checks-before.txt (W4); webroot-perms-before.txt | Restore the hardened values (750 directories, 640 files, owner www-data) | Open | Pending |
| F-03 | A3 | Unauthorized local account `testuser` with a weak password | Planted | 3 | 2 | 6 | High | checks-before.txt (A3); asset inventory. Password not tested directly (recorded decision) | Remove the account. Impact rises to 3 if the account has sudo rights | Open | Pending |
| F-04 | S2 | SSH password authentication is enabled (PermitRootLogin is correctly prohibit-password) | Pre-existing | 3 | 2 | 6 | High | checks-before.txt (S1/S2) | Set PasswordAuthentication no, after confirming key login works from a second session | Open | Pending |
| F-05 | F1 | Host firewall (UFW) is inactive | Planted | 2 | 2 | 4 | Medium | checks-before.txt (F1) | Allow 22, 80 and 443, default deny incoming, then enable | Open | Pending |
| F-06 | M2 | Pending package updates, including security updates for openssl and libssl3t64 | Pre-existing | 2 | 2 | 4 | Medium | checks-before.txt (M2, 11 packages); upgradable-before.txt (about 175 packages); lynis-before.txt (PKGS-7392) | Snapshot, apt update and upgrade, reboot for the kernel | Open | Pending |
| F-07 | L2 | fail2ban is not active, so SSH login attempts are not throttled | Pre-existing | 2 | 2 | 4 | Medium | checks-before.txt (L2) | Install and enable fail2ban with the sshd jail | Open | Pending |
| F-08 | W3 | Directory listing: autoindex module loaded and Indexes enabled on the web root | Planted | 3 | 1 | 3 | Medium | checks-before.txt (W3); dirlisting-http.html; dirlisting-https.html | Disable the autoindex module and remove Options +Indexes | Open | Pending |
| F-09 | W1 | Version banners exposed: ServerTokens Full, ServerSignature On | Planted | 2 | 1 | 2 | Low | checks-before.txt (W1); headers-http.txt; 404-signature-check.txt | Set ServerTokens Prod and ServerSignature Off | Open | Pending |
| F-10 | W5 | Security headers missing on HTTPS: CSP, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, HSTS | Pre-existing | 2 | 1 | 2 | Low | checks-before.txt (W5); nikto-https.txt.txt | Add the headers with mod_headers | Open | Pending |
| F-11 | none (Nikto) | Self-signed certificate with CN mismatch and no SAN | Pre-existing | 2 | 1 | 2 | Low | nikto-https.txt.txt; Nmap service scan | Reissue the certificate with a SAN, or accept the risk with a written reason (lab environment) | Open | Pending |

## How the 16 controls map to findings
| Control | Check | Baseline result | Finding |
|---|---|---|---|
| A1 | Only root has UID 0 | Pass | |
| A2 | No empty passwords | Pass | |
| A3 | Regular accounts are authorized | Fail | F-03 |
| S1 | Root cannot log in with a password over SSH | Pass | |
| S2 | SSH password authentication disabled | Fail | F-04 |
| F1 | Firewall active | Fail | F-05 |
| F2 | Only expected ports listening (22, 80, 443) | Pass | |
| W1 | Version banners suppressed | Fail | F-09 |
| W2 | /backup/ not publicly accessible | Fail | F-01 |
| W3 | autoindex module disabled | Fail | F-08 |
| W4 | No world-writable files in the web root | Fail | F-02 |
| W5 | Security headers present | Fail | F-10 |
| M1 | Unattended upgrades enabled | Pass | |
| M2 | No pending updates | Fail | F-06 |
| L1 | rsyslog active | Pass | |
| L2 | fail2ban active | Fail | F-07 |

Baseline: 6 of 16 passing (37.5%).

## Attack chain
F-04, F-03 and F-02 combine. SSH accepts passwords (F-04), `testuser` has a weak password (F-03), and the web root is world-writable (F-02). An attacker could log in as `testuser` and change the site content. F-07 means nothing slows the guessing down, and F-08 helps an attacker find F-01. Fixing F-04 or F-03 breaks the chain early, which is why they come before the Medium findings.

## Open points to resolve before the report
1. **Update count:** checks-before.txt (2026-10-28) lists 11 upgradable packages, while upgradable-before.txt (2026-10-29) lists about 175. The most likely cause is a package index refresh between the two captures. Confirm this and state which number the report uses.
2. **index.html permissions:** W4 lists index.html as world-writable, so the earlier note that only the directory was 777 is wrong. Confirm how this happened.
3. **testuser privileges:** check whether the account has sudo rights, since that raises F-03 from 6 to 9.
4. **F-01 origin:** confirm whether /backup/ and the dump were planted.
5. **Ratings are judgment calls:** F-06 (Medium) would move to High if a pending update fixes a remotely exploitable flaw.