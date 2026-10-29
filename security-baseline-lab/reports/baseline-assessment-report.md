# Security Baseline Assessment Lab — Baseline Report

**Project:** Arrowstack 1-Month Cyber Security Internship — Project 1
**Target:** apache-web-01 (Ubuntu Server 26.04 LTS, Apache 2.4.66)
**Assessor platform:** Kali Linux
**Report status:** Baseline evidence gathering complete. Risk register and remediation pending.

---

## 1. Objective

Establish an intentionally unhardened baseline on an existing Apache web server VM, then independently verify the resulting misconfigurations using host-level (Lynis) and network/web-level (Nmap, Nikto) tooling, cross-checked against a manual 16-control checklist. The goal is to produce a defensible before/after security posture comparison.

## 2. Scope

See `scope/scope-statement.md` and `inventory/asset-inventory.md` for full scope and asset details. In summary:

- **In scope:** apache-web-01 (host OS, Apache configuration, web root, firewall state, listening services)
- **Assessment network:** VirtualBox host-only segment 192.168.208.0/24 (apache-web-01 = .10, Kali = .30)
- **Out of scope:** SSH configuration was deliberately left unmodified for this assessment; no changes were made to Kali's existing NatNetwork adapter (10.0.0.0/24), which supports a separate internship task and was preserved throughout

## 3. Methodology

1. Snapshot the server in a known-hardened state, then intentionally introduce a defined set of misconfigurations to create an auditable "before" baseline.
2. Run a manual 16-control checklist against the unhardened server.
3. Run Lynis locally on the server for an OS/host-level audit.
4. Run Nmap and Nikto from Kali against the server for a network/web-level, outside-in view.
5. Manually verify any planted item not conclusively confirmed by automated tooling.
6. Hash (SHA-256) and preserve all evidence; copy to a second system (Windows host) to protect against VM snapshot rollback.

## 4. Environment Setup (2026-10-28)

- Snapshot `apache-web-01-HARDENED-final` taken as the known-good reference point.
- Planted misconfigurations:
  - `ServerTokens Full` / `ServerSignature On`
  - Directory indexing enabled (`autoindex` + `Options +Indexes` at the vhost `Directory` level)
  - `chmod 777` on the web root (`public_html`)
  - UFW disabled
  - Additional weak-password local user (`testuser`)
  - SSH configuration deliberately left unchanged (out of scope for this round)
- Snapshot `apache-web-01-UNHARDENED-baseline` taken to lock in the unhardened state (2026-10-28, 11:02 local).
- Evidence (`dirlisting-http/https.html`, `headers-http.txt`, `baseline-ground-truth.txt`) copied to the Windows host, SHA-256 verified.
- 16-control manual checklist run into `checks-before.txt`.

## 5. Evidence Gathering (2026-10-29)

### 5.1 Lynis (host-level audit)

Ran on apache-web-01 in the unhardened state.

- **Hardening index: 61/100** (262 tests performed)
- 1 warning: `PKGS-7392` — vulnerable/outdated packages
- 49 suggestions, including firewall (`FIRE-4590`), SSH hardening options, missing `fail2ban`/`auditd`, and password-policy gaps
- Lynis **correctly detected** the disabled firewall but **did not detect** any of the Apache-level misconfigurations (`ServerTokens`, directory indexing, `public_html` permissions) — confirmed by an empty grep against the full Lynis test log (`lynis-planted-check.txt`, 0 bytes). This is expected: Lynis audits the OS, not the web application layer.
- Pending OS updates: **176 packages**, **124** via the security pocket, including `apache2`, `openssh-server`, `openssl`, `sudo`, and the kernel.

Evidence: `evidence/2026-10-29/lynis-before.txt`, `lynis.log`, `lynis-report.dat`, `lynis-planted-check.txt`, `upgradable-before.txt`

### 5.2 Network baseline (server-side)

- `ss -tulpn` confirms only 3 externally reachable services: SSH (22), HTTP (80), HTTPS (443). Local-only services: DNS resolver, chrony, DHCP client.
- Interface `enp0s8` (host-only) confirmed at 192.168.208.10/24 — the correct assessment target address.

Evidence: `evidence/2026-10-29/listening-ports-before.txt`, `ip-addresses-before.txt`

### 5.3 Network path troubleshooting (Kali)

Initial Nmap scans reported all non-service ports as `filtered (no-response)` and took 7–40 minutes instead of seconds. Root cause, confirmed via `tcpdump` on the server: Kali's scan traffic was arriving via the Windows host's NAT engine (source 192.168.208.1), not directly from Kali, because Kali's host-only adapter had been repurposed for a separate internship task (NatNetwork, 10.0.0.2/24).

**Resolution:** added a second NIC to Kali (`eth1`, 192.168.208.30/24, host-only) alongside the existing NatNetwork adapter (`eth0`, preserved for the other task). Verified with `ip route get 192.168.208.10` showing a direct route via `eth1` with no gateway. New Kali snapshot taken (`Kali-dual-nic-baseline-lab`) to preserve the fix.

This troubleshooting is retained as evidence under `evidence/kali-evidence-2026-10-29/nat-path-prelim/`.

### 5.4 Nmap (post-fix, direct link)

```
sudo nmap -sS -sV -sC -p- -n -T4 192.168.208.10
```

- **22, 80, 443 open; 65,532 ports closed (reset)** — confirms no firewall filtering, consistent with UFW being disabled.
- Scan completed in **18.8 seconds** (vs. 7–40 minutes over the misrouted NAT path), and returned the target's MAC address, confirming a genuine Layer 2 path.
- Service detection: OpenSSH 10.2p1 (Ubuntu 2ubuntu3.5), Apache 2.4.66 (Ubuntu) with `OpenSSL/3.5.5` in the banner, self-signed TLS certificate (CN=apache-web-01, no SAN, valid 2026-08-25 to 2027-08-25).

Evidence: `evidence/kali-evidence-2026-10-29/nmap-full-tcp.{nmap,gnmap,xml}`

### 5.5 Nikto (HTTP and HTTPS)

8,284 requests per scan (HTTP: 388s, HTTPS: 481s).

Key findings:
- **`/backup/` directory indexing**, on both HTTP and HTTPS
- Missing security headers: `Content-Security-Policy`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`, `Strict-Transport-Security`
- TLS certificate hostname mismatch (self-signed, no SAN)
- Allowed HTTP methods: `HEAD, GET, POST, OPTIONS` (no risky methods exposed)

Evidence: `evidence/kali-evidence-2026-10-29/nikto-http.txt.txt`, `nikto-https.txt.txt`

### 5.6 Manual verification

**Exposed backup file.** The `/backup/` directory listing exposes `db-dump.sql.bak`. Confirmed publicly downloadable with no authentication:
```
HTTP/1.1 200 OK
Content-Type: application/x-trash
Last-Modified: Wed, 28 Oct 2026 07:46:23 GMT
```
Evidence: `backup-listing-http.html`, `backup-listing-https.html`, `db-dump-headers.txt`

**`ServerSignature On`.** Confirmed via the Apache 404 error page footer:
```
Apache/2.4.66 (Ubuntu) OpenSSL/3.5.5 Server at 192.168.208.10 Port 80
```
Evidence: `404-signature-check.txt`

**`public_html` permissions.** Confirmed via `stat` on the full directory chain:

| Path | Permissions | Owner |
|---|---|---|
| `/var/www` | 755 | root:root |
| `/var/www/apache-web-01` | 750 | www-data:www-data |
| `public_html/` | **777** | www-data:www-data |
| `public_html/backup/` | 755 | root:root |
| `db-dump.sql.bak` | 644 | root:root |

**Important nuance:** the `777` permission was applied only to `public_html` itself, not recursively. `backup/` and the exposed file both carry normal permissions. This means the world-writable web root and the backup-file exposure are **two distinct findings**, not one — the backup file is reachable via directory indexing + normal read permissions, not via the `777` misconfiguration.

Evidence: `evidence/2026-10-29/webroot-perms-before.txt`

**Weak-password `testuser` account.** Not independently tested in this round (decision made to limit scope). No automated tool (Lynis, Nmap, Nikto) detected this condition — Lynis only raised generic suggestions (`AUTH-9262`, `AUTH-9282`) unrelated to this specific account. Recorded as a known, scanner-silent gap.

### 5.7 Source traffic confirmation

Apache access log source IP counts, confirming the network fix and isolating troubleshooting traffic from the real assessment:

| Source | Requests | Explanation |
|---|---|---|
| 192.168.208.30 | 40,967 | Kali, direct host-only link (genuine assessment traffic) |
| 192.168.208.1 | 61 | Windows host NAT relay — artifact of the pre-fix misrouted scan |
| ::1 | 28 | Localhost — manual verification commands |
| 10.0.2.2 | 3 | Windows host via NAT adapter — early connectivity checks |

Evidence: `evidence/2026-10-29/source-ip-counts.txt`

## 6. Findings Summary

| # | Finding | Detected by | Severity (preliminary) |
|---|---|---|---|
| 1 | Host-based firewall (UFW) disabled | Lynis, Nmap | High |
| 2 | `/backup/` directory indexing exposes `db-dump.sql.bak` (unauthenticated) | Nikto, manual `curl` | High |
| 3 | Web root (`public_html`) world-writable (777, non-recursive) | Manual `stat` | Medium–High |
| 4 | `ServerTokens Full` — version/software disclosure | Nmap, curl banner | Low–Medium |
| 5 | `ServerSignature On` — version disclosure on error pages | Manual (404 footer) | Low–Medium |
| 6 | Missing HTTP security headers (CSP, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, HSTS) | Nikto | Low–Medium |
| 7 | 176 pending OS package updates (124 security) | Lynis + `apt list --upgradable` | Medium |
| 8 | Weak-password local account (`testuser`) | Not independently tested — no scanner detected it | Unrated / noted gap |

Full likelihood/impact ratings, CWE/OWASP mapping, and remediation guidance to be developed in the risk register.

## 7. Methodology Notes & Limitations

- **Tool versions:** Lynis 3.1.6 (flagged by Lynis itself as >6 months old at time of scan), Nikto v2.6.0, Nmap 7.99.
- **OS end-of-life data:** Ubuntu 26.04 was not present in Lynis's EOL database at time of scan; does not affect findings but is noted for completeness.
- **Timezone discrepancy:** apache-web-01 logs in UTC; Kali operated on UTC−4 (GMT-4) for this session. Timestamps in evidence files should be converted when cross-referencing server logs against Kali-side scan times (e.g., Nikto HTTP scan start 03:55 Kali time = 07:55 UTC on the server).
- **Network path artifact:** an initial ~40-minute Nmap run and 61 logged requests from 192.168.208.1 are the result of a since-corrected Kali network misconfiguration (traffic routed via VirtualBox NAT instead of the direct host-only link). Preserved as evidence but excluded from the primary findings.

## 8. Next Steps

1. Build the risk register (`risk-register/`) — formal likelihood/impact scoring and remediation guidance for each finding above.
2. Apply remediation on apache-web-01 and re-run the full evidence-gathering process (Lynis, Nmap, Nikto, 16-control checklist) to produce "after" evidence.
3. Produce a before/after comparison and final project write-up.