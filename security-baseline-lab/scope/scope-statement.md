# Scope Statement: Security Baseline Assessment

**Project:** Security Baseline Assessment Lab (Arrowstack Cyber Security Internship, Project 1)
**Author:** Marshel Mburu Macharia
**Date:** 2026-10-28
**Version:** 1.0

## 1. Scenario
[Fictional company name] is a small business that runs a public-facing web server. The IT manager wants to know how the server's configuration compares with a security baseline, and which gaps to fix first.

## 2. Stakeholder and decision
- **Primary stakeholder:** IT manager (non-technical)
- **Decision enabled:** which security fixes to schedule, and in what order

## 3. In scope
| Asset | Role | Address |
|---|---|---|
| apache-web-01 | Target: public web server | 192.168.208.10 |
| Kali Linux | Assessor workstation | 192.168.208.30 [confirm] |

## 4. Out of scope
- The Windows host machine
- The wazuh-manager, splunk-siem-01 and helpdesk-01 VMs
- Any system on the internet or on any other network

## 5. Authorization
All in-scope systems are owned by the author and run in an isolated VirtualBox lab. The author authorizes the assessment of the in-scope assets listed above.

## 6. Rules of engagement
- Scans run from Kali against apache-web-01 only
- No denial-of-service or destructive testing
- All evidence is stored in dated folders and hashed with SHA-256
- Some misconfigurations were introduced deliberately to simulate a poorly configured server. This is disclosed in the report

## 7. Method
16-control CIS-style checklist, Lynis audit, Nmap and Nikto scans. Findings are rated by Likelihood x Impact (1-3 each): 1-2 Low, 3-4 Medium, 6-9 High.

## 8. Success metrics
- Baseline result recorded before remediation: 6 of 16 controls passing (37.5%)
- Target after remediation: [for example, all High findings closed and at least 14 of 16 controls passing]
- Every finding has an evidence file, severity, fix and re-test result

## 9. Assumptions and limitations
- Single simulated server; results do not represent a production network
- Some findings were planted and others were already present; the report separates the two
- The 16-control baseline checks were captured on 2026-10-28, before this document was finalized. The Lynis, Nmap and Nikto scans came after it