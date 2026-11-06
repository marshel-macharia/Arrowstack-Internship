# Final Security Report: apache-web-01

| | |
|---|---|
| Prepared for | IT Manager, Kilele Traders Ltd (fictional; non-technical stakeholder) |
| Prepared by | Marshel Mburu Macharia |
| Asset assessed | `apache-web-01`, an Ubuntu 26.04 web server running Apache |
| Assessment period | 2026-10-28 to 2026-11-05 |
| Programme | Arrowstack Technologies Cyber Security Internship, Project 1 |
| Date | 2026-11-06 |

## 1. Summary

The web server was checked against 16 security controls. At the start it passed **6 of 16 (37.5%)**. Eleven findings were recorded (3 High, 5 Medium, 3 Low). Ten were fixed or reduced to a low risk, and one (a self-signed certificate) was accepted for the lab. After the fixes and a re-test it passes **15 of 16 (93.75%)**.

The most serious problems at the start were an open directory that let anyone download a backup file (F-01), a weak extra account (F-03), and SSH logins that accepted passwords (F-04). All three are closed. A large backlog of unapplied security updates (F-06) is also cleared.

One control still fails, and it is a documented decision: **W3**, because the feature that shows folder contents is blocked by configuration but still installed (a Low residual risk).

A note on the score: the update control (M2) was originally worded "no pending updates". At the final recheck on 2026-11-06 no Ubuntu security updates were pending (a new one, `ca-certificates`, had appeared that day and was installed), but 7 routine updates were still held back by Ubuntu's staged rollout and one third-party package (`wazuh-agent`, outside the assessment) was left alone. M2 is scored as a pass on the security-update criterion. Under the original strict wording the result would be 14 of 16 (87.5%). Both figures meet the project target of at least 14.

## 2. What was assessed and how

- **Scope:** one web server (A-01, including its SSH service), tested from one assessor machine running Kali Linux (A-02), on an isolated lab network. See `scope-statement.md`.
- **Method:** a 16-control checklist, plus three scanners: Lynis (system hardening audit), Nmap (open ports and services) and Nikto (web server weaknesses). Each was run before and after the fixes.
- **Scoring:** each finding is rated by Likelihood x Impact (1-3 each): 1-2 Low, 3-4 Medium, 6-9 High. See `risk-register.md`.
- **Fix order:** High findings first, then Medium, then Low. Fixes are recorded in `remediation-plan.md`.

## 3. Results

### 3.1 Control checklist

| ID | Control | Finding | Baseline | After |
|---|---|---|---|---|
| A1 | Only `root` has UID 0 | | Pass | Pass |
| A2 | No accounts with empty passwords | | Pass | Pass |
| A3 | No unexpected regular accounts | F-03 | **Fail** (`testuser`) | Pass |
| S1 | Root SSH login restricted | | Pass | Pass |
| S2 | SSH password login disabled | F-04 | **Fail** | Pass |
| F1 | Firewall active | F-05 | **Fail** | Pass |
| F2 | Only expected ports listening | | Pass | Pass |
| W1 | Web server hides version and OS | F-09 | **Fail** | Pass |
| W2 | `/backup/` not accessible | F-01 | **Fail** (HTTP 200) | Pass (404) |
| W3 | Directory listing module not loaded | F-08 | **Fail** | **Fail** (blocked, module kept) |
| W4 | No world-writable web files | F-02 | **Fail** | Pass |
| W5 | Browser security headers present | F-10 | **Fail** | Pass |
| M1 | Automatic updates enabled | | Pass | Pass |
| M2 | No pending (security) updates | F-06 | **Fail** | Pass (see section 1) |
| L1 | System logging active | | Pass | Pass |
| L2 | Brute-force protection (fail2ban) active | F-07 | **Fail** | Pass |
| | **Total** | | **6 / 16 (37.5%)** | **15 / 16 (93.75%)** |

### 3.2 Scanner comparison

| Tool | Baseline | After |
|---|---|---|
| Lynis hardening index | 61 | **69** |
| Lynis warnings | 1 | **0** |
| Lynis suggestions | 49 | 48 |
| Lynis tests performed | 262 | 264 |
| Nmap (all ports) | 22, 80, 443 open; 65,532 closed | 22, 80, 443 open; 65,532 filtered by the firewall |
| Nmap service detection | Apache 2.4.66 (Ubuntu) OpenSSL/3.5.5; OpenSSH 10.2p1 2ubuntu3.5 | Apache (no version); OpenSSH 10.2p1 2ubuntu3.8 |
| Nikto | `/backup/` listing exposed on HTTP and HTTPS; missing CSP, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, HSTS; version banner; certificate mismatch | No `/backup/` listing; no version banner; headers present. Remaining: certificate mismatch, HSTS flagged on port 80 (by design), informational notes (see 3.3) |

Lynis improved modestly because it measures general hardening and did not detect most of the planted weaknesses (for example the banner, directory listing and file permissions). The control checklist is the better measure of what was fixed here.

### 3.3 Items the scanners still report

- **X-Content-Type-Options "not set" (Nikto, both ports):** the header was verified present on normal, error, OPTIONS and HTTPS responses (`f10-xcto-verification.txt`). This is treated as a scanner false positive; the cause was not determined.
- **HSTS missing on port 80:** by design. HSTS is sent on HTTPS only because browsers ignore it over plain HTTP.
- **X-Frame-Options:** Nikto notes the header is deprecated. The Content-Security-Policy `frame-ancestors 'none'` setting provides the protection.
- **Allowed HTTP methods (GET, POST, OPTIONS, HEAD):** informational; no risky methods are allowed.
- **Certificate mismatch:** the server uses a self-signed certificate (F-11, residual risk R-2).

## 4. Residual risks

All residual risks are rated Low and accepted for this lab. They are listed in full in `risk-register.md` (R-1 to R-6): the loaded directory-listing module, the self-signed certificate, deferred and future updates, the SSH version string, the lack of an HTTP to HTTPS redirect, and the remaining generic Lynis suggestions.

## 5. Recommendations

1. **Keep patching.** New security updates appeared within two days of the first patching round. Check weekly and keep automatic updates on.
2. **Replace the self-signed certificate** with one from a trusted authority (or an internal CA) before any real use.
3. **Optional hardening:** disable the `autoindex` module, add an HTTP to HTTPS redirect, and work through the remaining Lynis suggestions (password aging, `auditd`, ModSecurity).
4. **Do not leave backup or test files in web folders.** Keep backups outside the web root.
5. **Repeat this assessment** after major changes and at regular intervals, using the same checklist so results stay comparable.

## 6. Limitations

- Some misconfigurations were planted on 2026-10-28 to simulate a poorly configured server; the risk register marks which findings were planted and which pre-existing.
- The after-remediation checklist ran with a script reconstructed from the baseline output, because the original commands were not kept as a script. The output format matches the baseline.
- The `testuser` weak-password risk was not tested directly; the scanners did not detect it and a targeted authentication test was skipped. The account has since been removed.
- Lab environment: isolated network, one server, one assessor machine, self-signed certificate. Results do not describe a production system.
- Nmap's full-port scan used `--max-retries 1` after the firewall change, because dropped packets made the default settings slow. The baseline scan did not use that option.
- The M2 wording and the two scores are explained in section 1. Nikto reported one false positive (section 3.3). Lynis's score does not reflect most of the fixes made.
- The 16 controls are the author's own checklist, modelled on the CIS benchmarks; this is not an official CIS assessment.

## 7. Evidence

Evidence files (SHA-256 hashed) are stored in `security-baseline-lab/evidence/`, in dated folders: `2026-10-28`, `2026-10-29`, `2026-11-03`, `2026-11-05`, `2026-11-05-kali`, `2026-11-05-after-server` and `2026-11-05-after-kali`. Each finding's files are listed in `remediation-plan.md` and `risk-register.md`. The files `f08-after.txt` (banner, F-09) and `f09-*.txt` (directory listing, F-08) were named in the working order of the fixes and were not renamed. VirtualBox snapshots: `apache-web-01-UNHARDENED-baseline` (before) and `apache-web-01-HARDENED-after-remediation` (after).