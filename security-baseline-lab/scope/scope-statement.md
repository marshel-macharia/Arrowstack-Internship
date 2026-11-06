# Scope Statement: Security Baseline Assessment

**Project:** Security Baseline Assessment Lab (Arrowstack Cyber Security Internship, Project 1)
**Author:** Marshel Mburu Macharia
**Date:** 2026-11-06
**Version:** 1.2 (see change log at the end)

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

All services on apache-web-01 are in scope, including its SSH service (checks S1 and S2, finding F-04, and the fail2ban control L2).

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
- Fixes were applied by the author on apache-web-01 (2026-11-03 and 2026-11-05) after a snapshot was taken, and tested again with the same checklist and the same three scanners

## 7. Method
16-control CIS-style checklist, Lynis audit, Nmap and Nikto scans, run before and after remediation. Findings are rated by Likelihood x Impact (1-3 each): 1-2 Low, 3-4 Medium, 6-9 High.

The 16 controls are the author's own checklist, modelled on the CIS Ubuntu Linux and CIS Apache HTTP Server 2.4 benchmarks. This is not an official CIS benchmark assessment, and the controls were selected and worded by the author (see References).

## 8. Success metrics
- Baseline recorded before remediation: 6 of 16 controls passing (37.5%)
- Baseline Lynis hardening index: 61 (Lynis 3.1.6, 2026-10-29)
- Targets after remediation, and results (2026-11-05):

| Target | Result |
|---|---|
| All High findings closed | Met: F-01, F-03 and F-04 closed |
| Medium findings closed or formally accepted with a reason | Met: F-02, F-05, F-06 and F-07 closed; F-08 mitigated, with the loaded `autoindex` module accepted as a Low residual risk |
| At least 14 of 16 controls passing | Met: 15 of 16 (93.75%). Only W3 still fails (see section 9 for the M2 wording) |
| Lynis hardening index | No numeric threshold was set in advance (the placeholder in v1.1 is removed). Result: 69, up from 61, with 0 warnings (baseline 1) |

- Every finding has an evidence file, severity, fix and re-test result (see `risk-register.md` and `remediation-plan.md`)

## 9. Assumptions and limitations
- Single simulated server; results do not represent a production network
- Some findings were planted and others were already present; the asset inventory and the report separate the two
- The 16-control baseline checks were captured on 2026-10-28, before this document was finalized. The Lynis, Nmap and Nikto scans came after it
- NAT-path artifact: the first Nmap run on 2026-10-29 reached apache-web-01 through the VirtualBox NAT path instead of the host-only link. The Windows host (192.168.208.1), which is out of scope, therefore appears in the server access log with 61 requests. Those requests come from that first scan, not from a separate system under assessment. The results are kept as preliminary evidence (evidence/2026-10-29/nat-path-prelim); the assessment results come from the direct scans after Kali's host-only adapter was fixed
- The weak password on the `testuser` account was not verified by any scanner and was not tested directly (a deliberate decision, recorded in the work log). The report states that scanners did not detect it. The account was removed in remediation
- The checklist is the author's own and is not an official CIS certification or benchmark result
- The after-remediation checklist was run with a script reconstructed from the baseline output (`run-checks.sh`), because the original baseline commands were not kept as a script. The output format matches `checks-before.txt`
- Control M2 was worded "no pending updates" in risk register v1.0. At the final recheck on 2026-11-06, after installing the updates that had appeared since 2026-11-05 (including the Ubuntu security update `ca-certificates`), no Ubuntu security updates were pending. 7 non-security packages were still held back by Ubuntu's phased rollout, and one package from a third-party repository (`wazuh-agent`, outside the assessment scope; a Wazuh agent must not be newer than its manager) was left alone (`m2-recheck-2026-11-06-before.txt`, `m2-recheck-2026-11-06-after.txt`, `checks-after-final.txt`). M2 is scored as a pass on the security-update criterion. Under the original strict wording the after score would be 14 of 16 (87.5%). Both figures are reported, and the target of at least 14 is met either way
- The after-remediation full-port Nmap scan used `--max-retries 1`, because the firewall drops packets to closed ports and the default settings are very slow. The baseline scan did not use that option
- Nikto reported one false positive after remediation (X-Content-Type-Options "not set", although the header was verified on four request types). The cause was not determined

## References
- Center for Internet Security, CIS Benchmarks (Ubuntu Linux and Apache HTTP Server 2.4): https://www.cisecurity.org/cis-benchmarks
- CISOfy, Lynis security auditing tool: https://cisofy.com/lynis/
- Nmap Project, Nmap network scanner: https://nmap.org
- Nikto web server scanner: https://github.com/sullo/nikto

## Change log
- **v1.2 (2026-11-06):** recorded the after-remediation results against the targets; removed the Lynis placeholder; stated that SSH on apache-web-01 is in scope; added limitations for the reconstructed checklist script, the M2 wording and score, the Nmap option change and the Nikto false positive; added the remediation step to the rules of engagement
- **v1.1 (2026-11-03):** named the fictional company, confirmed the Kali address, added the out-of-scope Kali NAT interface, the Splunk forwarder note, the NAT-path disclosure, the Lynis metric, the baseline naming statement and references; set the after-remediation targets as provisional until the risk register exists
- **v1.0 (2026-10-28):** initial scope statement