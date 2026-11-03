# Asset Inventory

**Updated:** 2026-11-03 (finding IDs use the F- prefix; asset IDs use the A- prefix)

## Systems
| ID | Asset | Type | OS / software | Address | Role | Criticality | Data sensitivity |
|---|---|---|---|---|---|---|---|
| A-01 | apache-web-01 | Server VM | Ubuntu Server 26.04 LTS, Apache 2.4.66 | 192.168.208.10 | Public web server | High | Medium |
| A-02 | Kali | Workstation VM | Kali Linux 2026.2 | 192.168.208.30 (eth1, host-only) | Assessor workstation | Low | Low |

- **Criticality (A-01):** High, because it is the only public-facing service in the scenario.
- **Data sensitivity (A-01):** Medium. A placeholder file named like a database export (`db-dump.sql.bak`) was publicly downloadable, but it was empty (0 bytes; evidence: db-dump-size.txt), so no data was exposed. A real backup in the same place would justify High.
- **A-02:** Kali's eth0 (10.0.0.2/24, NatNetwork) belongs to another internship task and is out of scope.

## Services and ports on apache-web-01
Source: direct Nmap `-p-` scan from Kali over the host-only link, 2026-10-29 (evidence/2026-10-29). Result: 22, 80 and 443 open, 65,532 ports closed.

| Port | Service | Version | Notes |
|---|---|---|---|
| 22/tcp | SSH | OpenSSH 10.2p1 Ubuntu 2ubuntu3.5 | Administrative access |
| 80/tcp | HTTP | Apache 2.4.66 (Ubuntu) | Public web server |
| 443/tcp | HTTPS | Apache 2.4.66 (Ubuntu), OpenSSL 3.5.5 | Self-signed certificate, CN=apache-web-01, no SAN |

## Installed software of interest on apache-web-01
| Software | Version | Notes |
|---|---|---|
| Apache HTTP Server | 2.4.66 | Web server |
| OpenSSH server | 10.2p1 | Listed among the pending updates |
| OpenSSL | 3.5.5 | Listed among the pending updates |
| Splunk forwarder | Installed at /opt/splunkforwarder | On the target, but the Splunk SIEM it reports to (splunk-siem-01) is not assessed. Explains the Lynis HOME-9304 result |
| Lynis | 3.1.6 | Audit tool run on the target on 2026-10-29 |

## Accounts on apache-web-01
| Account | Type | Status |
|---|---|---|
| root | System | Authorized (SSH key-only: PermitRootLogin prohibit-password; evidence: checks-before.txt, section S1/S2) |
| marshel | Administrator | Authorized |
| splunkfwd | Service account [confirm: Splunk forwarder] | Authorized, documented |
| testuser | Local user | Unauthorized (control A3, finding F-03) |

## Finding origin: planted vs pre-existing
Finding IDs are assigned in the risk register. This table records where each issue came from so the report can separate deliberate misconfigurations from real ones.

| Issue | Origin | Notes |
|---|---|---|
| ServerTokens Full / ServerSignature On (version banners) | Planted | Introduced 2026-10-28 |
| Directory listing (autoindex, Options +Indexes) | Planted | Introduced 2026-10-28 |
| World-writable web root (chmod 777 on public_html) | Planted | checks-before.txt (W4) lists both public_html and public_html/index.html as world-writable; backup/ and db-dump.sql.bak had normal permissions (webroot-perms-before.txt). [confirm: how index.html became world-writable] |
| UFW disabled | Planted | Introduced 2026-10-28 |
| testuser with a weak password | Planted | Not detected by scanners and not tested directly |
| /backup/ directory and db-dump.sql.bak | [confirm: planted or pre-existing] | The file's Last-Modified time (2026-10-28 07:46 GMT) points to the same day as the planted changes |
| SSH password authentication enabled | Pre-existing | Default setting; SSH was deliberately left unweakened [confirm] |
| fail2ban not active | Pre-existing | Not part of the original build |
| Pending package updates | Pre-existing | checks-before.txt (2026-10-28) lists 11 upgradable packages; upgradable-before.txt (2026-10-29) lists about 175, including apache2, openssh-server, openssl, sudo and the kernel |
| Missing security headers (CSP, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, HSTS) | Pre-existing | Found by Nikto |
| Self-signed certificate, CN mismatch, no SAN | Pre-existing | Built in the original hardening work |