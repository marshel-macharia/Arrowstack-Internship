# Remediation Plan: Web Application Security Review Lab

| | |
|---|---|
| **Project** | Arrowstack Internship, Project 2: Web Application Security Review Lab |
| **Target** | OWASP Juice Shop 20.4.0-SNAPSHOT (Docker, Kali Linux), intentionally vulnerable lab application |
| **Prepared by** | Marshel Mburu Macharia |
| **Version / Date** | v1.0 / 2026-11-11 |
| **Related documents** | `scope-statement.md`, `risk-register.md`, `worklog.md`, `final-security-report.md` |

> **Lab note:** Juice Shop is deliberately insecure and its source code is not being modified in this project. Where a fix belongs in the application code, it is documented here as a recommendation and **not** implemented. Where a compensating control could be applied at the network edge, an nginx reverse proxy (`127.0.0.1:8080` in front of the app on `127.0.0.1:3000`) was used and then retested.

## 1. Summary

| ID | Finding | Original rating | Fix type | Status |
|---|---|---|---|---|
| WA-01 | SQL injection auth bypass (`/rest/user/login`) | High (9) | Code change | Recommended, not implemented |
| WA-02 | DOM-based XSS in search | High (9) | Code change | Recommended, not implemented |
| WA-03 | Missing/misconfigured security headers | Medium (4) | Proxy config | **Mitigated at proxy (partial)** |
| WA-04 | IDOR on `/rest/basket/{id}` | High (6) | Code change | Recommended, not implemented |
| WA-05 | MD5 password hash exposed in JWT payload | High (6) | Code change | Recommended, not implemented |
| WA-06 | No brute-force protection on login | High (6) | Proxy config + code | **Mitigated at proxy (partial)** |
| WA-07 | Mass assignment / admin self-registration (`POST /api/Users/`) | High (9) | Code change | Recommended, not implemented |
| WA-08 | Exposed `/ftp` directory listing | High (9) | Proxy config + deployment | **Mitigated at proxy (partial)** |

"Partial" means the proxy control closes the tested attack path, but the underlying weakness still exists in the application (see section 3).

## 2. Prioritisation

| Priority | Target timeframe | Findings | Reason |
|---|---|---|---|
| P1: Immediate | 0 to 7 days | WA-01, WA-07, WA-08 | Direct authentication bypass, privilege escalation, and exposure of sensitive files |
| P2: Short term | 8 to 30 days | WA-02, WA-04, WA-05, WA-06 | Account compromise, data exposure, and credential attacks |
| P3: Planned | 30 to 60 days | WA-03 (residual items) | Defence-in-depth hardening |

## 3. Findings and remediation

### WA-01: SQL injection authentication bypass (High, 9)
- **Issue:** The login endpoint concatenates user input into a SQL query. The payload `' OR 1=1--` logged in as `admin@juice-sh.op`.
- **Recommended fix:**
  - Use parameterised queries or prepared statements (or an ORM's bound parameters) for all database access.
  - Validate input server-side (type, length, format).
  - Run the application with a least-privilege database account.
  - Return generic error messages and never expose SQL errors to the client.
- **Defence in depth:** WAF rules can detect common SQLi patterns, but they do not replace the code fix.
- **Verification:** Replay the original payload and confirm the response is `401`, with no token issued.
- **Status:** Not implemented (application code change required).

### WA-02: DOM-based XSS in search (High, 9)
- **Issue:** The search term is rendered into the DOM unsafely. The payload `<iframe src="javascript:alert(`xss`)">` executed script.
- **Recommended fix:**
  - Treat all user-controlled data as untrusted and use contextual output encoding.
  - Avoid `innerHTML` and Angular's `bypassSecurityTrust*` methods on user input; rely on the framework's built-in sanitisation.
  - Move to a strict CSP without `unsafe-inline` and `unsafe-eval` (requires refactoring the front end).
- **Note:** The CSP added in WA-03 does **not** stop this attack, because it allows `unsafe-inline` and `unsafe-eval` for the app to function.
- **Verification:** Replay the payload and confirm no script executes.
- **Status:** Not implemented (application code change required).

### WA-03: Missing/misconfigured security headers (Medium, 4)
- **Issue:** No CSP, wildcard CORS (`Access-Control-Allow-Origin: *`), and the deprecated `Feature-Policy` header.
- **Implemented (nginx):** Removed the wildcard CORS and `Feature-Policy` headers, and added `Content-Security-Policy`, `Referrer-Policy`, and `Permissions-Policy`.
- **Evidence:** `wa-03-retest-headers.txt`, `wa-03-retest-browser-render.png`, `nginx-juice-shop.conf` (all in `evidence/2026-11-11/`). The retest shows `200 OK`, the three new headers present, and the two weak headers absent. The shop renders normally through the proxy.
- **Residual items:**
  - The CSP allows `unsafe-inline` and `unsafe-eval`, which weakens XSS protection (see WA-02).
  - `X-Recruiting: /#/jobs` is still returned (minor information disclosure) and can be hidden with `proxy_hide_header X-Recruiting;`.
  - HSTS was not added because the lab runs over plain HTTP on localhost. In production, serve over TLS and enable `Strict-Transport-Security`.
- **Status:** Mitigated at proxy (partial).

### WA-04: IDOR on `/rest/basket/{id}` (High, 6)
- **Issue:** An authenticated user can read another user's basket by changing the numeric ID.
- **Recommended fix:**
  - Enforce server-side authorisation on every request: the basket must belong to the user identified by the session/token.
  - Deny by default, and never trust client-supplied IDs.
  - Consider non-sequential identifiers as an additional measure, not as the primary control.
- **Verification:** Request a basket belonging to another user and confirm `403`/`404`.
- **Status:** Not implemented (application code change required).

### WA-05: MD5 password hash exposed in JWT payload (High, 6)
- **Issue:** The JWT payload contains the user's MD5 password hash. MD5 is fast and unsalted, so such hashes are easy to crack, and JWT payloads are only encoded, not encrypted.
- **Recommended fix:**
  - Never place password hashes or other secrets in tokens; keep JWT claims to the minimum (user ID, role, expiry).
  - Store passwords with a modern, slow, salted algorithm (Argon2id or bcrypt).
  - Migrate existing hashes on next login and invalidate issued tokens.
- **Verification:** Decode a new token and confirm no hash or sensitive field is present.
- **Status:** Not implemented (application code change required).

### WA-06: No brute-force protection on login (High, 6)
- **Issue:** Unlimited login attempts were accepted.
- **Implemented (nginx):** Per-IP rate limit on `/rest/user/login` (5 requests/minute, burst of 3, `429` on excess).
- **Evidence:** `wa-06-retest.txt`. Ten rapid failed logins returned `401` four times and then `429` six times.
- **Residual items:** A per-IP limit slows a single-source attack but does not stop distributed attempts or targeted attacks on one account. Recommended application-level controls:
  - Account lockout or progressive delays.
  - CAPTCHA after repeated failures.
  - Multi-factor authentication.
  - Alerting on failed-login spikes.
- **Status:** Mitigated at proxy (partial).

### WA-07: Mass assignment / admin self-registration (High, 9)
- **Issue:** `POST /api/Users/` accepted `"role":"admin"` from the client, letting anyone register as an administrator.
- **Recommended fix:**
  - Use an allow-list of accepted fields on registration and ignore everything else.
  - Assign roles server-side only, and never from client input.
  - Add automated tests that attempt to set privileged fields.
- **Verification:** Register with `"role":"admin"` and confirm the created account has the default customer role.
- **Status:** Not implemented (application code change required).

### WA-08: Exposed `/ftp` directory listing (High, 9)
- **Issue:** `/ftp` listed files including `package-lock.json.bak`, `incident-support.kdbx`, `legal.md`, and `acquisitions.md`.
- **Implemented (nginx):** Requests to `/ftp` return `403`, matched case-insensitively.
- **Evidence:** `wa-08-retest.txt`. Both `/ftp` and `/FTP` return `403`.
- **Residual items:** The files still exist on the application server; the proxy only hides them. Recommended:
  - Remove the directory listing and the folder from the deployment.
  - Never store backups, password databases, or confidential documents in a web-accessible path.
  - Treat anything in the exposed password database (`.kdbx`) as compromised: rotate those credentials.
- **Status:** Mitigated at proxy (partial).

## 4. Verification and evidence

- All retest evidence is stored in `evidence/2026-11-11/` and hashed with SHA-256 (`all-evidence-hashes.txt`); integrity was verified with `sha256sum -c`, and every file returned `OK`.
- Day 1 (original findings) evidence is in `evidence/2026-11-10/` with its own hash list, providing the before/after comparison.
- Findings marked "Not implemented" were not retested, because no change was made to them.
- The Kali VM's clock is set to `America/New_York` (EST, UTC-5), so some screenshot filenames show 2026-11-10 even though the work took place on 2026-11-11 UTC.

## 5. Residual risk and next steps

1. Implement the P1 code fixes (WA-01, WA-07), and remove the `/ftp` content (WA-08).
2. Implement the P2 fixes and retest each finding with its original proof of concept.
3. Update `risk-register.md` with residual ratings for WA-03, WA-06, and WA-08 once the proxy controls are accounted for.
4. Re-run the full assessment after remediation to confirm no regressions.