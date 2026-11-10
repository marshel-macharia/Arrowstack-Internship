# Risk Register: Web Application Security Review

**Project:** Web Application Security Review Lab (Arrowstack Cyber Security Internship, Project 2)
**Author:** Marshel Mburu Macharia
**Date:** 2026-11-10
**Version:** 1.0 (see change log at the end)

Severity method (same as Project 1): Likelihood x Impact (1-3 each). 1-2 Low, 3-4 Medium, 6-9 High.

## Summary

| ID | Finding | OWASP Category | Likelihood | Impact | Severity | Status |
|---|---|---|---|---|---|---|
| WA-01 | SQL injection — authentication bypass | A03:2021 Injection | 3 | 3 | 9 High | Open |
| WA-02 | DOM-based XSS in search | A03:2021 Injection | 3 | 3 | 9 High | Open |
| WA-03 | Missing/misconfigured security headers | A05:2021 Security Misconfiguration | 2 | 2 | 4 Medium | Open |
| WA-04 | IDOR — basket access | A01:2021 Broken Access Control | 3 | 2 | 6 High | Open |
| WA-05 | Password hash exposed in JWT (MD5) | A02:2021 Cryptographic Failures | 2 | 3 | 6 High | Open |
| WA-06 | No brute-force protection on login | A07:2021 Identification and Authentication Failures | 3 | 2 | 6 High | Open |
| WA-07 | Mass assignment — admin self-registration | A01:2021 Broken Access Control | 3 | 3 | 9 High | Open |
| WA-08 | Exposed /ftp directory listing | A05:2021 Security Misconfiguration | 3 | 3 | 9 High | Open |

7 High, 1 Medium. All findings open pending Day 2 remediation.

## WA-01: SQL injection — authentication bypass

- **Category:** OWASP A03:2021 — Injection
- **Endpoint:** `POST /rest/user/login`
- **Description:** The login endpoint builds a SQL query from the `email` field without sanitizing it. Submitting `' OR 1=1--` as the email bypasses the password check entirely and authenticates as the first user in the database.
- **Reproduction:**
  1. Send `POST /rest/user/login` with body `{"email":"' OR 1=1--","password":"1234"}`
  2. Response returns `200 OK` with a valid JWT and `"umail":"admin@juice-sh.op"`
- **Evidence:** `wa-01-request.txt`, `wa-01-response.txt`, `wa-01-repeater.png`
- **Severity:** Likelihood 3 x Impact 3 = 9, High
- **Fix:** use parameterized queries or an ORM with bound parameters instead of string-concatenated SQL

## WA-02: DOM-based cross-site scripting in search

- **Category:** OWASP A03:2021 — Injection (Cross-Site Scripting, DOM-based)
- **Endpoint:** client-side search component, `#/search?q=`
- **Description:** The Angular search component inserts the `q` URL parameter into the page without sanitizing it. A crafted URL containing `<iframe src="javascript:alert(\`xss\`)">` executes arbitrary JavaScript in the victim's browser, with no server round-trip involved.
- **Reproduction:**
  1. Navigate to `#/search?q=<iframe src="javascript:alert(\`xss\`)">`
  2. An alert box fires; the application's own challenge tracker confirms "DOM XSS" solved
- **Delivery vector:** a crafted link sent to a victim, e.g. via phishing
- **Evidence:** `wa-02-alert.png`, `wa-02-dom.png`
- **Severity:** Likelihood 3 x Impact 3 = 9, High
- **Fix:** sanitize/encode the `q` parameter before inserting it into the DOM; do not bypass Angular's built-in sanitization

## WA-03: Missing and misconfigured security headers

- **Category:** OWASP A05:2021 — Security Misconfiguration
- **Endpoint:** all responses (checked on `/`)
- **Description:** No Content-Security-Policy, Permissions-Policy, or Referrer-Policy headers are sent. The deprecated Feature-Policy header is present instead of Permissions-Policy. Access-Control-Allow-Origin is set to `*` (any origin). A custom `X-Recruiting` header discloses an internal route. The absence of a CSP directly enabled WA-02 to execute without any browser-side mitigation.
- **Reproduction:** `curl -sI http://127.0.0.1:3000`
- **Evidence:** `wa-03-headers.txt`
- **Severity:** Likelihood 2 x Impact 2 = 4, Medium
- **Fix:** add a Content-Security-Policy restricting script/style/connect sources; add Permissions-Policy and `Referrer-Policy: strict-origin-when-cross-origin`; restrict Access-Control-Allow-Origin to known origins; remove the X-Recruiting header; add HSTS once served over HTTPS

## WA-04: Insecure direct object reference (IDOR) — basket access

- **Category:** OWASP A01:2021 — Broken Access Control
- **Endpoint:** `GET /rest/basket/{id}`
- **Description:** The endpoint returns basket contents for any basket ID without verifying the ID belongs to the requesting user's token. A logged-in customer (basket ID 6, per their own token) could read basket ID 4, belonging to a different user (UserId 11).
- **Reproduction:**
  1. Log in as test1@test.com (own basket ID 6)
  2. Send `GET /rest/basket/4` with the own valid Bearer token
  3. Response returns `200 OK` with `"UserId":11` and that user's basket contents
- **Evidence:** `wa-04-request.txt`, `wa-04-response.txt`, `wa-04-repeater.png`
- **Severity:** Likelihood 3 x Impact 2 = 6, High
- **Fix:** on every basket request, verify `basket.UserId === token.userId` server-side before returning data; reject with 403 otherwise. Consider non-sequential (UUID) basket IDs as defense-in-depth

## WA-05: Password hash exposed in JWT payload (weak hashing algorithm)

- **Category:** OWASP A02:2021 — Cryptographic Failures
- **Endpoint:** JWT issued by `POST /rest/user/login`
- **Description:** The JWT issued at login embeds the user's password hash in its payload. JWTs are signed, not encrypted, so the base64-encoded payload is readable by anyone who has the token. The hash itself is MD5 (32 hex characters), a fast, broken algorithm unsuitable for password storage.
- **Reproduction:** decode the payload segment of any issued JWT with `base64 -d`; the `password` field is visible in plain JSON
- **Evidence:** `wa-05-decoded-jwt.txt`
- **Severity:** Likelihood 2 x Impact 3 = 6, High
- **Fix:** never include password hashes (or any sensitive field) in JWT payloads; use bcrypt or argon2 instead of MD5 for password storage

## WA-06: No brute-force protection on login

- **Category:** OWASP A07:2021 — Identification and Authentication Failures
- **Endpoint:** `POST /rest/user/login`
- **Description:** The login endpoint applies no rate limiting, account lockout, CAPTCHA, or delay after repeated failed attempts. Repeated incorrect-password requests all return an identical `401 Unauthorized` with no escalating friction, allowing unlimited automated password guessing.
- **Reproduction:** send `POST /rest/user/login` with a known email and a wrong password repeatedly (10+ times); every response is an unchanged `401`
- **Evidence:** `wa-06-request.txt`, `wa-06-response.txt`, `wa-06-bruteforce.png`
- **Severity:** Likelihood 3 x Impact 2 = 6, High
- **Fix:** add rate limiting or progressive delays per account/IP; lock accounts after N failed attempts with a cooldown; add a CAPTCHA after repeated failures

## WA-07: Mass assignment — admin self-registration

- **Category:** OWASP A01:2021 — Broken Access Control (Mass Assignment)
- **Endpoint:** `POST /api/Users/`
- **Description:** The public registration endpoint accepts a client-supplied `role` field and assigns it directly to the new account, with no server-side restriction to the default `customer` role. Any unauthenticated visitor can self-register as an administrator.
- **Reproduction:**
  1. Send `POST /api/Users/` with a normal registration body plus `"role":"admin"`
  2. Response returns `201 Created` with `"role":"admin"` on the new account
- **Evidence:** `wa-07-request.txt`, `wa-07-response.txt`, `wa-07-repeater.png`
- **Severity:** Likelihood 3 x Impact 3 = 9, High
- **Fix:** whitelist only the fields a public registration endpoint should accept (email, password, security question/answer); hardcode `role: "customer"` server-side regardless of what the client sends

## WA-08: Exposed /ftp directory listing

- **Category:** OWASP A05:2021 — Security Misconfiguration
- **Endpoint:** `GET /ftp/`
- **Description:** The `/ftp` path has directory listing enabled and is reachable without authentication. It exposes ten files, including backup files (`package.json.bak`, `package-lock.json.bak`, `coupons_2013.md.bak`), internal documents (`acquisitions.md`, `legal.md`), and a KeePass password database file (`incident-support.kdbx`). None of these are intended for public web access.
- **Reproduction:** `curl -s http://127.0.0.1:3000/ftp/` or browse to `/ftp` directly
- **Evidence:** `wa-08-directory-listing.txt`, `wa-08-ftp-browser.png`
- **Severity:** Likelihood 3 x Impact 3 = 9, High
- **Fix:** disable directory listing on the web server for this path; move backup and non-public files outside the web root entirely; restrict `/ftp` to authenticated internal use only if still needed

## Change log
- **v1.0 (2026-11-10):** initial risk register, all 8 Day 1 findings (WA-01 through WA-08)