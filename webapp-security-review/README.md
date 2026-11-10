# Web Application Security Review Lab

Arrowstack Cyber Security Internship — Project 2. An authorized review of OWASP Juice Shop (an intentionally vulnerable web application), run locally in Docker as a stand-in for a company's web shop.

## Status

Day 1 of 3 complete: 8 findings documented and evidenced (target was 8). Day 2: remediation and retesting. Day 3: final report and submission.

| Metric | Result |
|---|---|
| Findings documented | 8 (WA-01 through WA-08) |
| High severity | 7 |
| Medium severity | 1 |
| Findings remediated | Pending (Day 2) |

## Target

- OWASP Juice Shop, image `bkimminich/juice-shop:latest`
- Digest: `sha256:877fc77b12d72b42e486eb09b6b1711cc56514306d92006b284e7e7cf076a809`
- App version: `20.4.0-SNAPSHOT`
- Bound to `127.0.0.1:3000` on the assessor's own Kali VM only

## Documents

- `scope-statement.md` — target, authorization, rules of engagement, method, success metrics
- `risk-register.md` — all findings with OWASP category, reproduction steps, evidence references, severity, and fix
- `remediation-plan.md` — planned and applied fixes (added Day 2)
- `reports/final-security-report.md` — narrative summary for the stakeholder (added Day 3)
- `worklog.md` — dated log of work performed

## Evidence layout

Evidence is kept in dated folders under `evidence/`, one per day of testing.

```
evidence/2026-11-10/        Day 1: setup + 8 findings
  app-version.txt           Juice Shop version
  image-digest.txt          Docker image digest
  docker-ps.txt             container + port binding
  docker-version.txt        Docker version
  juice-shop-headers.txt    baseline response headers
  listening-3000.txt        confirms loopback-only binding
  wa-0X-request.txt         raw HTTP request for finding X
  wa-0X-response.txt        raw HTTP response for finding X
  wa-0X-*.png               supporting screenshots
  wa-0X-hashes.txt          SHA-256 hashes for finding X's evidence
  all-evidence-hashes.txt   SHA-256 hashes for every file in this folder
```

## Reproducing the lab

```bash
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo docker pull bkimminich/juice-shop:latest
sudo docker run -d --name juice-shop -p 127.0.0.1:3000:3000 bkimminich/juice-shop:latest
```

Verify the version and digest match this report:

```bash
curl -s http://127.0.0.1:3000/rest/admin/application-version
sudo docker inspect --format '{{index .RepoDigests 0}}' bkimminich/juice-shop:latest
```

## Verifying evidence hashes

From inside an evidence date folder:

```bash
sha256sum -c all-evidence-hashes.txt
```

Every line should report `OK`. A mismatch means a file was altered after the hash was taken.

## Scope and authorization

Full detail in `scope-statement.md`. In short: the only in-scope asset is the Juice Shop container on `127.0.0.1:3000`, run by the author on the author's own machine. No real systems, users, or data are involved. See the scope statement for the complete rules of engagement.