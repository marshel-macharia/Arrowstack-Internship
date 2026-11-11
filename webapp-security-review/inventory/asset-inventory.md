# Asset Inventory: Web Application Security Review Lab

| | |
|---|---|
| **Project** | Arrowstack Internship, Project 2: Web Application Security Review Lab |
| **Prepared by** | Marshel Mburu Macharia |
| **Version / Date** | v1.0 / 2026-11-11 |
| **Related documents** | `scope-statement.md`, `risk-register.md`, `remediation-plan.md`, `final-security-report.md` |

## 1. In-scope assets

| ID | Asset | Type | Details | Role in project |
|---|---|---|---|---|
| A-01 | Kali Linux VM (`kali`) | Host / VM | OS release: Kali GNU/Linux Rolling; timezone `America/New_York` (EST, UTC-5); `eth0` `10.0.0.2/24` (NAT lab network); `eth1` `192.168.208.30/24` (host-only adapter, used only for evidence transfer) | Runs Docker, nginx, and all testing tools |
| A-02 | Docker Engine | Container runtime | `docker.io` 28.5.2; requires `sudo` (user is not in the `docker` group); default bridge `docker0` at `172.17.0.1/16` | Hosts the target container |
| A-03 | Container `juice-shop` | Container | Container ID `1b603b8ae3bc`; image `bkimminich/juice-shop:latest`; digest `sha256:877fc77b12d72b42e486eb09b6b1711cc56514306d92006b284e7e7cf076a809`; port `127.0.0.1:3000->3000/tcp`; restart policy: `no` (does not start automatically after a reboot; started manually with `sudo docker start juice-shop`) | Runs the target application |
| A-04 | OWASP Juice Shop | Web application (target) | Version `20.4.0-SNAPSHOT`; intentionally vulnerable; direct URL `http://127.0.0.1:3000` | **Primary target** of the review |
| A-05 | nginx reverse proxy | Compensating control | Version: nginx/1.30.4; config `/etc/nginx/conf.d/juice-shop.conf`; listens on `127.0.0.1:8080`; upstream `127.0.0.1:3000`; added 2026-11-11 | Applies header, `/ftp`, and login rate-limit controls (WA-03, WA-06, WA-08) |

## 2. Accounts

| Account | Type | Use in project |
|---|---|---|
| `admin@juice-sh.op` | Built-in administrator | Accessed through SQL injection in WA-01 |
| `test1@test.com` | Tester-created customer account | Used for WA-04 (IDOR) and WA-05 (JWT review) |

## 3. Endpoints tested

| Endpoint | Method | Finding(s) |
|---|---|---|
| `/` (response headers) | GET | WA-03 |
| `/rest/user/login` | POST | WA-01, WA-05, WA-06 |
| Search (client-side route `/#/search`) | GET | WA-02 |
| `/rest/basket/{id}` | GET | WA-04 |
| `/api/Users/` | POST | WA-07 |
| `/ftp` | GET | WA-08 |

## 4. Data assets exposed during testing

All data belongs to the lab application and is fictional.

| Asset | Where found | Finding | Sensitivity if this were production |
|---|---|---|---|
| `incident-support.kdbx` | `/ftp` | WA-08 | High (password database) |
| `package-lock.json.bak` | `/ftp` | WA-08 | Medium (dependency disclosure) |
| `legal.md`, `acquisitions.md` | `/ftp` | WA-08 | Medium to High (confidential business documents) |
| MD5 password hash inside JWT payload | Login response | WA-05 | High (credential material) |

## 5. Tools used

| Tool | Purpose |
|---|---|
| Firefox + developer tools | Manual testing, DOM inspection (WA-02), screenshots |
| Burp Suite (Repeater): | Request replay and capture (WA-01 evidence) |
| `curl` | Header, status-code, and rate-limit retests |
| `sha256sum` | Evidence integrity hashing |
| `scp` (from PowerShell) | Evidence transfer from Kali to the Windows repo |
| Git / GitHub | Version control and publishing (`Arrowstack-Internship/webapp-security-review`) |

## 6. Evidence locations

| Location | Contents |
|---|---|
| Kali: `~/webapp-review/evidence/2026-11-10/` | Day 1 findings evidence (32 files) with individual hashes and `all-evidence-hashes.txt` |
| Kali: `~/webapp-review/evidence/2026-11-11/` | Day 2 retest evidence: `nginx-juice-shop.conf`, `wa-03-retest-headers.txt`, `wa-03-retest-browser-render.png`, `wa-06-retest.txt`, `wa-08-retest.txt`, `all-evidence-hashes.txt` |
| Repo: `Arrowstack-Internship/webapp-security-review/` | Copies of all evidence plus the project documents |

## 7. Exposure and trust boundaries

- Juice Shop is bound to `127.0.0.1:3000` and nginx to `127.0.0.1:8080`, so neither service is reachable from other machines.
- SSH on Kali was started only temporarily for evidence transfer and stopped afterwards.
- Because the proxy is an edge control, it only protects traffic that goes through port `8080`. Traffic to port `3000` bypasses it, which is acceptable here because that port is localhost-only.

## 8. Out of scope

Any system not listed above, including the Project 1 lab (`apache-web-01`), the Windows host, and any internet-facing service. No testing was performed against them.