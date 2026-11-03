# Scope Statement: Security Baseline Assessment

**Project:** Security Baseline Assessment Lab (Arrowstack Cyber Security Internship, Project 1)
**Author:** Marshel Mburu Macharia
**Date:** 2026-11-03
**Version:** 1.1 (see change log at the end)

## 1. Scenario
Kilele Traders Ltd (fictional) is a small business that runs a public-facing web server. The IT manager wants to know how the server's configuration compares with a security baseline, and which gaps to fix first.

## 2. Stakeholder and decision
- **Primary stakeholder:** IT manager (non-technical)
- **Decision enabled:** which security fixes to schedule, and in what order

## 3. In scope
| Asset | Role | Address |
|---|---|---|
| apache-web-01 | Target: public web server | 192.168.208.10 |
| Kali Linux | Assessor workstation | 192.168.208.30 (eth1, host-only) |

## 4. Out of scope
- The Windows host machine
- The wazuh-manager, splunk-siem-01 and helpdesk-01 VMs
- The Splunk forwarder on apache-web-01 is noted in the inventory, but the Splunk SIEM it reports to is not assessed
- Kali's second interface (eth0, 10.0.0.2/24, NatNetwork), which belongs to another internship task and is not used for this assessment
- Any system on the internet or on any other network

## 5. Authorization
All in-scope systems are owned by the author and run in an isolated VirtualBox lab. The author authorizes the assessment of the in-scope assets listed above.

## 6. Rules of engagement
- Scans run from Kali against apache-web-01 only, over the host-only link (192.168.208.0/24)
- No denial-of-service or destructive testing
- All evidence is stored in dated folders and hashed with SHA-256
- Some misconfigurations were introduced deliberately to simulate a poorly configured server. This is disclosed in the report

## 7. Method
16-control CIS-style checklist, Lynis audit, Nmap and Nikto scans. Findings are rated by Likelihood x Impact (1-3 each): 1-2 Low, 3-4 Medium, 6-9 High.

The 16 controls are the author's own checklist, modelled on the CIS Ubuntu Linux and CIS Apache HTTP Server 2.4 benchmarks. This is not an official CIS benchmark assessment, and the controls were selected and worded by the author (see References).

## 8. Success metrics
- Baseline recorded before remediation: 6 of 16 controls passing (37.5%)
- Baseline Lynis hardening index: 61 (Lynis 3.1.6, 2026-10-29)
- Targets after remediation (to be finalized once the risk register is complete):
  - All High findings closed
  - Medium findings closed or formally accepted with a reason
  - At least 14 of 16 controls passing
  - Lynis hardening index of at least [value to be set after the risk register]
- Every finding has an evidence file, severity, fix and re-test result

## 9. Assumptions and limitations
- Single simulated server; results do not represent a production network
- Some findings were planted and others were already present; the asset inventory and the report separate the two
- The 16-control baseline checks were captured on 2026-10-28, before this document was finalized. The Lynis, Nmap and Nikto scans came after it
- NAT-path artifact: the first Nmap run on 2026-10-29 reached apache-web-01 through the VirtualBox NAT path instead of the host-only link. The Windows host (192.168.208.1), which is out of scope, therefore appears in the server access log with 61 requests. Those requests come from that first scan, not from a separate system under assessment. The results are kept as preliminary evidence (evidence/2026-10-29/nat-path-prelim); the assessment results come from the direct scans after Kali's host-only adapter was fixed
- The weak password on the `testuser` account was not verified by any scanner and was not tested directly (a deliberate decision, recorded in the work log). The report states that scanners did not detect it
- The checklist is the author's own and is not an official CIS certification or benchmark result

## References
- Center for Internet Security, CIS Benchmarks (Ubuntu Linux and Apache HTTP Server 2.4): https://www.cisecurity.org/cis-benchmarks
- CISOfy, Lynis security auditing tool: https://cisofy.com/lynis/
- Nmap Project, Nmap network scanner: https://nmap.org
- Nikto web server scanner: https://github.com/sullo/nikto

## Change log
- **v1.1 (2026-11-03):** named the fictional company, confirmed the Kali address, added the out-of-scope Kali NAT interface, the Splunk forwarder note, the NAT-path disclosure, the Lynis metric, the baseline naming statement and references; set the after-remediation targets as provisional until the risk register exists
- **v1.0 (2026-10-28):** initial scope statement