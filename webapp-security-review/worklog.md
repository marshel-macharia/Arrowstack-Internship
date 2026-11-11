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

## Day 2: 2026-11-11 (final day)

**Time spent:** [2.5 hours]

**Goal:** Remediate what can be fixed at the network edge, retest, complete the remaining documents, and submit. Planned Day 2 and Day 3 were combined into this single day, because all 8 findings had already been completed and evidenced on Day 1.

### Activities
1. Installed nginx on Kali and configured a reverse proxy (`127.0.0.1:8080` in front of Juice Shop on `127.0.0.1:3000`) in `/etc/nginx/conf.d/juice-shop.conf`.
2. Applied three compensating controls:
   - **WA-03:** removed the wildcard CORS and `Feature-Policy` headers; added `Content-Security-Policy`, `Referrer-Policy`, and `Permissions-Policy`.
   - **WA-08:** blocked `/ftp` with a `403`, matched case-insensitively so `/FTP` is covered too.
   - **WA-06:** rate-limited `/rest/user/login` (5 requests/minute, burst 3, `429` on excess).
3. Retested all three through the proxy and saved the results as evidence.
4. Confirmed in the browser that the shop still renders normally through the proxy.
5. Saved the nginx config as evidence, then hashed every Day 2 file with SHA-256 and verified with `sha256sum -c` (all `OK`).
6. Wrote `remediation-plan.md` (v1.0) and `asset-inventory.md` (v1.0).
7. Final-security-report.md.
8. Commit and push to GitHub.

### Retest results
| Finding | Test | Result |
|---|---|---|
| WA-03 | `curl -sI` through the proxy | `200 OK`; three new headers present; CORS wildcard and `Feature-Policy` absent. `X-Recruiting` still returned; CSP allows `unsafe-inline`/`unsafe-eval` (partial mitigation) |
| WA-08 | `/ftp` and `/FTP` | `403` for both |
| WA-06 | 10 rapid failed logins | `401` x4, then `429` x6 |

### Issues and resolutions
- **First retest returned `502 Bad Gateway`.** nginx was running but could not reach the app. `sudo docker ps -a` showed the `juice-shop` container as `Exited (255)`, stopped when Kali was restarted. Resolved with `sudo docker start juice-shop`; the app returned `200` after about a minute. The `/ftp` results from the first run were valid (nginx answers those itself), but the WA-03 and WA-06 results were discarded and redone after the app was running.
- **`permission denied` on the Docker socket.** The `kali` user is not in the `docker` group; used `sudo` for Docker commands rather than adding the user to the group.
- **Rate-limit counter carried over between runs.** Waited 60 seconds before the repeat WA-06 test so earlier `429` responses did not distort the result.

### Notes
- The Kali VM clock is set to `America/New_York` (EST, UTC-5). Screenshot filenames therefore show 2026-11-10 (for example `Screenshot_2026-11-10_23_51_38.png`) for work done on 2026-11-11 in UTC. `curl` output timestamps are in GMT. The two are consistent (23:51 EST = 04:51 GMT).
- Five findings (WA-01, WA-02, WA-04, WA-05, WA-07) require application code changes, so they are documented as recommendations in `remediation-plan.md` and were not retested.
- The proxy controls are partial mitigations: the weaknesses still exist in the application behind them (see `remediation-plan.md`, section 3).

### Evidence (Day 2)
`~/webapp-review/evidence/2026-11-11/`: `nginx-juice-shop.conf`, `wa-03-retest-headers.txt`, `wa-03-retest-browser-render.png`, `wa-06-retest.txt`, `wa-08-retest.txt`, `all-evidence-hashes.txt`