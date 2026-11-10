# Worklog: Web Application Security Review (Project 2)

## 2026-11-10 (Day 1 of 3)

- Reviewed the Arrowstack handbook's Project 2 brief: Web Application Security Review Lab, using OWASP Top 10, Burp Suite Community, and a Docker lab
- Chose OWASP Juice Shop as the target, run in Docker on Kali, bound to 127.0.0.1:3000 only
- Set up repo folder structure under `webapp-security-review/` (scope, inventory, evidence, risk-register, remediation, reports), mirroring the Project 1 layout
- Installed docker.io on Kali, pulled and ran `bkimminich/juice-shop:latest` (app version 20.4.0-SNAPSHOT, digest sha256:877fc77b12d72b42e486eb09b6b1711cc56514306d92006b284e7e7cf076a809)
- Captured setup evidence: docker ps, docker version, response headers, listening ports (evidence/2026-11-10)
- Configured Burp Suite Community Edition v2026.3.2 as an intercepting proxy using its built-in browser
- Wrote scope-statement.md v1.0, later updated to v1.1 with captured tool versions and Day 1 results
- Tested and documented 8 findings (WA-01 through WA-08), covering injection, broken access control, cryptographic failures, authentication failures, and security misconfiguration:
  - WA-01: SQL injection — authentication bypass on login
  - WA-02: DOM-based XSS in search
  - WA-03: missing/misconfigured security headers
  - WA-04: IDOR on basket access
  - WA-05: password hash exposed in JWT (MD5)
  - WA-06: no brute-force protection on login
  - WA-07: mass assignment — admin self-registration
  - WA-08: exposed /ftp directory listing
- Saved request/response pairs and screenshots for each finding; hashed every evidence file individually (wa-0X-hashes.txt) and as a full-folder manifest (all-evidence-hashes.txt)
- Wrote risk-register.md v1.0 with all 8 findings, severities, and recommended fixes
- Copied the evidence folder from Kali to the Windows repo

**Next (Day 2):** remediate and retest at least 3 findings with before/after evidence; consider additional findings if time allows
**Next (Day 3):** write the remediation plan and final security report, finish README, verify hashes, commit and push