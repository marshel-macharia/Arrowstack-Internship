# Scope Statement: Web Application Security Review

**Project:** Web Application Security Review Lab (Arrowstack Cyber Security Internship, Project 2)
**Author:** Marshel Mburu Macharia
**Date:** 2026-11-10
**Version:** 1.0 (see change log at the end)

## 1. Scenario
Kilele Traders Ltd (fictional) is preparing to launch an online shop. Before launch, the IT manager wants an authorized security review of the shop application, to learn which weaknesses it contains, how serious they are, and which to fix first. The application is OWASP Juice Shop, an intentionally vulnerable web application, run locally as a stand-in for the company's shop.

## 2. Stakeholder and decision
- **Primary stakeholder:** IT manager (non-technical)
- **Decision enabled:** which web application fixes to schedule before launch, and in what order
- **Measurable benefit:** a ranked list of findings, each with evidence, a severity rating, a safe fix and a retest result

## 3. In scope
| Asset | Role | Address |
|---|---|---|
| OWASP Juice Shop (Docker container `juice-shop`) | Target: web application | http://127.0.0.1:3000 |
| Kali Linux | Assessor workstation (also hosts the target, see section 9) | localhost |

- **Application version:** 20.4.0-SNAPSHOT
- **Image:** bkimminich/juice-shop:latest, digest sha256:877fc77b12d72b42e486eb09b6b1711cc56514306d92006b284e7e7cf076a809
- **Bind address:** 127.0.0.1 only, so the application cannot be reached from any other machine
- **Tools:** Burp Suite Community Edition v2026.3.2, Chromium (Burp's built-in browser), curl, Docker 28.5.2 (Kali's docker.io package)

All features of the application reachable on http://127.0.0.1:3000 are in scope: the storefront, user registration and login, search, the basket and checkout, the REST API under `/rest` and `/api`, and the application's static files.

## 4. Out of scope
- Every other system, including apache-web-01, the wazuh-manager, splunk-siem-01 and helpdesk-01 VMs, and the Windows host
- Kali's other network interfaces and the Project 1 lab network (192.168.208.0/24)
- Any system on the internet, including any public Juice Shop instance
- Denial-of-service, resource-exhaustion and brute-force flooding tests
- Attacks on the Docker engine, the Kali operating system or the container host (container escape)
- Social engineering

## 5. Authorization
The target is a deliberately vulnerable application that the author runs on the author's own machine in an isolated lab. The author authorizes the testing of the in-scope assets listed above. No real user data, credentials or systems are involved.

## 6. Rules of engagement
- Testing is done only against http://127.0.0.1:3000
- The container is published on the loopback address only (`-p 127.0.0.1:3000:3000`)
- Testing is manual, using Burp Suite Community as an intercepting proxy; Community has no automated scanner, so nothing here comes from an automated scan
- No denial-of-service or destructive testing; the application can be reset by recreating the container
- Each finding is tested with the smallest request that proves it, and no data is exfiltrated beyond what is needed as evidence
- All evidence is stored in dated folders (`evidence/2026-11-10` and later) and hashed with SHA-256
- Juice Shop is built to be vulnerable, so findings are expected. This is disclosed in the report, and its built-in challenge hints are not used as a source of findings
- Fixes are applied by the author after the baseline findings are recorded, and each fix is tested again with the same request that proved the original finding

## 7. Method
Manual testing guided by the OWASP Top 10 ([edition: confirm, see References]), covering these categories: broken access control, injection, authentication failures, cross-site scripting, security misconfiguration and sensitive data exposure.

Each finding gets an ID (WA-01, WA-02, ...), an OWASP category, reproduction steps, an evidence file (Burp request and response, screenshot), a severity rating, a safe fix and a retest result.

Findings are rated by Likelihood x Impact (1-3 each): 1-2 Low, 3-4 Medium, 6-9 High. This is the same method as Project 1, so the two projects can be compared. Likelihood reflects how easy the weakness is to exploit, and impact reflects the effect on the shop's data and customers if it were exploited.

Remediation is done as a configuration change or a compensating control in front of the application where the application code cannot be changed (for example, response headers or a reverse proxy rule). Where no safe fix is possible, the finding is documented with the code-level fix a developer should apply.

## 8. Success metrics
- At least 8 findings documented, each with evidence, an OWASP category and a severity
- Every High finding has reproduction steps, a recommended fix and a retest result
- At least 3 findings remediated and retested, with before and after evidence
- Evidence files hashed and the hashes verified before submission
- Results (to be filled in at the end of the project):

| Target | Result |
|---|---|
| Findings documented | Met: 8 findings (WA-01 through WA-08), exceeding the 8-finding target |
| High findings with fix and retest | 7 of 8 findings rated High (WA-01, WA-02, WA-04, WA-05, WA-06, WA-07, WA-08); WA-03 rated Medium. Fixes and retests to be completed and recorded here on Day 2 |
| Findings remediated and retested | To be completed on Day 2 |
| Evidence hashes verified | Day 1 evidence hashed per finding (wa-0X-hashes.txt) and as a full-folder manifest (all-evidence-hashes.txt) |

## 9. Assumptions and limitations
- Single intentionally vulnerable application; results do not represent a production shop
- Assessor and target run on the same machine (Kali), because the container is bound to the loopback address. A real assessment would normally test from a separate machine
- The application and tooling were downloaded over Kali's internet-facing interface for installation only; no testing uses that interface
- The `latest` image tag changes over time, so the image digest is recorded to make the test reproducible
- Burp Suite Community has no automated scanner and limited tooling, so coverage depends on manual testing and is not exhaustive
- Time-boxed to three days, so not every Juice Shop weakness is tested
- Some fixes are compensating controls and not code changes, and a compensating control may not fully remove the underlying weakness
- The OWASP Top 10 mapping is the author's judgement, and a finding can fit more than one category

## References
- OWASP Foundation, OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP Juice Shop project: https://owasp.org/www-project-juice-shop/
- PortSwigger, Burp Suite Community Edition: https://portswigger.net/burp/communityedition
- Docker documentation: https://docs.docker.com/

## Change log
- **v1.1 (2026-11-10):** filled in the application version, image digest, and tool versions; recorded Day 1 results in the success metrics table (8 of 8 findings documented)
- **v1.0 (2026-11-10):** initial scope statement for Project 2