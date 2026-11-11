# Final Security Report: Web Application Security Review Lab

| | |
|---|---|
| **Project** | Arrowstack Internship, Project 2: Web Application Security Review Lab |
| **Target** | OWASP Juice Shop 20.4.0-SNAPSHOT (intentionally vulnerable lab application) |
| **Tester** | Marshel Mburu Macharia |
| **Testing dates** | 2026-11-10 (assessment), 2026-11-11 (remediation and retest) |
| **Version** | v1.0 |
| **Related documents** | `scope-statement.md`, `risk-register.md`, `remediation-plan.md`, `asset-inventory.md`, `worklog.md` |

## 1. Executive summary

A security review was performed on OWASP Juice Shop, a deliberately vulnerable web application, running in a Docker container on an isolated Kali Linux lab machine. The review identified **8 findings: 7 rated High and 1 rated Medium**. All 8 were reproduced and supported with hashed evidence.

The most serious issues allow an attacker to bypass authentication (WA-01), register as an administrator (WA-07), read other users' data (WA-04), and access sensitive files through an exposed directory (WA-08).

In the second phase, an nginx reverse proxy was placed in front of the application as a compensating control. It **partially mitigated three findings** (WA-03, WA-06, WA-08), and each fix was retested and documented. The remaining **five findings (WA-01, WA-02, WA-04, WA-05, WA-07) can only be fixed in the application code**. They are documented with specific recommendations in `remediation-plan.md` and were not retested, because the application was not modified.

| Rating | Count | Findings |
|---|---|---|
| High | 7 | WA-01, WA-02, WA-04, WA-05, WA-06, WA-07, WA-08 |
| Medium | 1 | WA-03 |

## 2. Scope and methodology

### 2.1 Scope
- **In scope:** the Juice Shop application (`127.0.0.1:3000`), its container, and the nginx proxy added during remediation (`127.0.0.1:8080`). The full list is in `asset-inventory.md`.
- **Out of scope:** every other system, including the Project 1 lab, the Windows host, and any internet-facing service.
- **Environment:** the application and proxy were bound to localhost only, so no service was reachable from other machines.

### 2.2 Approach
1. **Setup:** deployed Juice Shop in Docker on Kali and recorded the application version and image digest as evidence.
2. **Assessment (Day 1):** manual testing of the application as an unauthenticated user and with a self-registered test account. Each finding was reproduced, captured (requests, responses, screenshots), and hashed individually and as a set with SHA-256.
3. **Risk rating:** each finding was recorded in `risk-register.md` with a score. The ratings in this report are carried over from that register.
4. **Remediation and retest (Day 2):** applied edge controls with nginx where possible, then repeated the original tests through the proxy and saved the results as evidence.
5. **Reporting:** documented findings, remediation guidance, and the asset inventory.

Tools: Firefox with developer tools, [Burp Suite Repeater], `curl`, `sha256sum`, and `scp` (see `asset-inventory.md`). Findings are mapped to the OWASP Top 10 (2021) categories for reference.

### 2.3 Limitations
- This was a lab exercise against an intentionally insecure application, not a production assessment.
- It covers the eight findings documented here and is not an exhaustive test of the application.
- Retesting covers only the three findings mitigated at the proxy.

## 3. Findings

| ID | Finding | Rating | OWASP Top 10 (2021) | Location |
|---|---|---|---|---|
| WA-01 | SQL injection authentication bypass | High (9) | A03 Injection | `POST /rest/user/login` |
| WA-02 | DOM-based cross-site scripting in search | High (9) | A03 Injection | Search (`/#/search`) |
| WA-03 | Missing/misconfigured security headers | Medium (4) | A05 Security Misconfiguration | All responses |
| WA-04 | Insecure direct object reference on baskets | High (6) | A01 Broken Access Control | `GET /rest/basket/{id}` |
| WA-05 | MD5 password hash exposed in JWT payload | High (6) | A02 Cryptographic Failures | Login response / token |
| WA-06 | No brute-force protection on login | High (6) | A07 Identification and Authentication Failures | `POST /rest/user/login` |
| WA-07 | Mass assignment / admin self-registration | High (9) | A01 Broken Access Control | `POST /api/Users/` |
| WA-08 | Exposed `/ftp` directory listing | High (9) | A05 Security Misconfiguration | `/ftp` |

### WA-01: SQL injection authentication bypass (High, 9)
The login endpoint builds its database query from unsanitised input. Submitting `' OR 1=1--` as the email logged the tester in as `admin@juice-sh.op`. **Impact:** full authentication bypass, including administrator access. **Evidence:** `wa-01-request.txt`, `wa-01-response.txt`, `wa-01-repeater.png`, `wa-01-hashes.txt`.

### WA-02: DOM-based XSS in search (High, 9)
The search term is written into the page without safe handling. The payload `<iframe src="javascript:alert(`xss`)">` executed JavaScript, and Juice Shop's own "DOM XSS" challenge banner confirmed it. **Impact:** script execution in a victim's browser, enabling session theft or page manipulation. **Evidence:** `wa-02-alert.png`, `wa-02-dom.png`.

### WA-03: Missing/misconfigured security headers (Medium, 4)
Responses had no `Content-Security-Policy`, allowed any origin through a wildcard `Access-Control-Allow-Origin`, and sent the deprecated `Feature-Policy` header. **Impact:** weaker browser-side defences against XSS and cross-origin abuse. **Evidence:** `wa-03-*` files in `evidence/2026-11-10/`.

### WA-04: IDOR on baskets (High, 6)
An authenticated user could read another user's basket by changing the ID in `/rest/basket/{id}`. **Impact:** unauthorised access to other users' data. **Evidence:** `wa-04-*` files (test account `test1@test.com`).

### WA-05: MD5 password hash exposed in JWT payload (High, 6)
The JWT issued at login contained the user's MD5 password hash. JWT payloads are encoded, not encrypted, and MD5 is fast and unsalted. **Impact:** credential material is exposed to anyone who obtains the token and is easy to crack offline. **Evidence:** `wa-05-*` files.

### WA-06: No brute-force protection on login (High, 6)
The login endpoint accepted unlimited attempts with no throttling or lockout. **Impact:** password guessing and credential stuffing are practical. **Evidence:** `wa-06-*` files.

### WA-07: Mass assignment / admin self-registration (High, 9)
`POST /api/Users/` accepted `"role":"admin"` from the client, so anyone could register as an administrator. **Impact:** privilege escalation to full administrative control. **Evidence:** `wa-07-*` files.

### WA-08: Exposed `/ftp` directory listing (High, 9)
The `/ftp` path listed files including `package-lock.json.bak`, `incident-support.kdbx`, `legal.md`, and `acquisitions.md`. **Impact:** disclosure of a password database, confidential documents, and dependency information. **Evidence:** `wa-08-*` files.

## 4. Before and after: mitigated findings

| Finding | Before (2026-11-10) | Control applied (nginx) | After (2026-11-11) | Evidence |
|---|---|---|---|---|
| WA-03 | No CSP; wildcard CORS; deprecated `Feature-Policy` | Removed the two weak headers; added `Content-Security-Policy`, `Referrer-Policy`, `Permissions-Policy` | `200 OK` with the three new headers; CORS wildcard and `Feature-Policy` absent; shop renders normally | `wa-03-retest-headers.txt`, `wa-03-retest-browser-render.png` |
| WA-08 | `/ftp` listing and files accessible | `/ftp` blocked (case-insensitive) | `403` for `/ftp` and `/FTP` | `wa-08-retest.txt` |
| WA-06 | Unlimited login attempts | Rate limit of 5 requests/minute with a burst of 3 on `/rest/user/login` | Ten rapid failed logins gave `401` x4, then `429` x6 | `wa-06-retest.txt` |

The nginx configuration is saved as `nginx-juice-shop.conf` in `evidence/2026-11-11/`.

**These are partial mitigations**, because the weaknesses remain in the application behind the proxy:
- **WA-03:** the CSP allows `unsafe-inline` and `unsafe-eval` so the application keeps working, which means it does **not** stop WA-02. `X-Recruiting: /#/jobs` is still returned, and HSTS was not added because the lab uses plain HTTP on localhost.
- **WA-06:** a per-IP limit slows a single attacker but does not stop distributed attacks or targeted guessing against one account.
- **WA-08:** the files still exist on the application server and are only hidden by the proxy.

## 5. Remediation summary

Full guidance, verification steps, and priorities are in `remediation-plan.md`.

| Priority | Timeframe | Findings | Main action |
|---|---|---|---|
| P1: Immediate | 0 to 7 days | WA-01, WA-07, WA-08 | Parameterised queries; allow-list registration fields and assign roles server-side; remove sensitive files from the web path and rotate exposed credentials |
| P2: Short term | 8 to 30 days | WA-02, WA-04, WA-05, WA-06 | Output encoding and sanitisation; server-side ownership checks; remove hashes from tokens and use Argon2id/bcrypt; account lockout, CAPTCHA, and MFA |
| P3: Planned | 30 to 60 days | WA-03 (residual) | Strict CSP without `unsafe-*`, hide `X-Recruiting`, TLS with HSTS |

## 6. Conclusion

The application had serious weaknesses across authentication, access control, data exposure, and configuration. That is expected for a deliberately vulnerable target, but the exercise followed a realistic process: scope, evidence, risk rating, remediation, retest, and reporting.

Edge controls reduced exposure for three findings quickly and measurably, but they do not replace secure code. The five code-level findings, especially WA-01 and WA-07, should be fixed first in any real environment. A full retest should follow once the fixes are in place.

## 7. Appendix: evidence and integrity

| Location | Contents |
|---|---|
| `evidence/2026-11-10/` | Day 1 evidence for all 8 findings (32 files), each hashed individually, plus `all-evidence-hashes.txt` |
| `evidence/2026-11-11/` | Retest evidence and `nginx-juice-shop.conf`, with `all-evidence-hashes.txt` |

All hashes are SHA-256 and were verified with `sha256sum -c` (every file `OK`). The Kali VM clock is set to `America/New_York` (EST, UTC-5), so some screenshot filenames show 2026-11-10 for work done on 2026-11-11 UTC.

**Sign-off**

| Role | Name | Date |
|---|---|---|
| Tester | Marshel Mburu Macharia | 2026-11-11 |
