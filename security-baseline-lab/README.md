# Security Baseline Assessment Lab

A before-and-after security assessment of a small Apache web server, done as Project 1 of the Arrowstack Technologies Cyber Security Internship.

I measured a deliberately misconfigured server against a 16-control checklist, confirmed the weaknesses with three scanners, rated each one by risk, fixed them, and tested again. Every claim in the reports points to an evidence file with a SHA-256 hash.

## Result at a glance

| Measure | Before | After |
|---|---|---|
| Controls passing (16-control checklist) | 6 / 16 (37.5%) | **15 / 16 (93.75%)** |
| Lynis hardening index | 61 | **69** |
| Lynis warnings | 1 | **0** |
| Open ports (Nmap, all 65,535) | 22, 80, 443 open; the rest closed | 22, 80, 443 open; the rest dropped by the firewall |
| Web server version disclosed | Yes (Apache 2.4.66, Ubuntu, OpenSSL) | No |
| Public backup file download | Yes (HTTP 200) | No (404) |

15 of 16 counts the update control (M2) as a pass because no Ubuntu security updates were pending at the final recheck (7 routine updates were deferred by Ubuntu's staged rollout and one third-party package was left alone); under its original strict wording ("no pending updates") the result is 14 of 16 (87.5%). Both figures are explained in the scope statement (section 9) and meet the project target of at least 14. The one control that still fails is W3: the directory-listing module is still installed, although listings are blocked and verified.

## Scenario and scope

Kilele Traders Ltd (a fictional company) runs a public-facing web server. Its non-technical IT manager wants to know how the server compares with a security baseline and which gaps to fix first.

- **Target:** `apache-web-01`, Ubuntu Server 26.04 LTS with Apache 2.4.66 (192.168.208.10)
- **Assessor:** Kali Linux (192.168.208.30), over an isolated VirtualBox host-only network
- **In scope:** the target server and all its services, including SSH
- **Out of scope:** the Windows host, the other lab VMs, and anything outside the lab

Some misconfigurations were introduced on purpose to simulate a poorly configured server. The risk register shows which findings were planted and which were already present.

## Method

1. Snapshot the server in a known-good state, plant the misconfigurations, and snapshot the baseline.
2. Run a 16-control checklist, then Lynis (host audit), Nmap (ports and services) and Nikto (web server weaknesses) against the baseline.
3. Rate each finding by Likelihood x Impact (1-3 each): 1-2 Low, 3-4 Medium, 6-9 High.
4. Fix the findings in risk order, validating each fix from Kali.
5. Reboot, then rerun the same checklist and the same three scanners to produce the "after" evidence.

## Findings and outcome

| ID | Finding | Rating | Outcome |
|---|---|---|---|
| F-01 | Public `/backup/` listing with a downloadable `db-dump.sql.bak` | High (9) | Closed |
| F-02 | World-writable web root and `index.html` | Medium (3) | Closed |
| F-03 | Unneeded account `testuser` with a weak password | High (6) | Closed |
| F-04 | SSH password authentication enabled | High (6) | Closed |
| F-05 | Host firewall (UFW) disabled | Medium (4) | Closed |
| F-06 | Large backlog of pending updates, including security updates | Medium (4) | Closed |
| F-07 | No brute-force protection (fail2ban inactive) | Medium (4) | Closed |
| F-08 | Directory listing enabled | Medium (3) | Mitigated (module left installed, accepted as a Low residual risk) |
| F-09 | Server banner disclosing version and OS | Low (2) | Closed |
| F-10 | Browser security headers missing | Low (2) | Closed |
| F-11 | Self-signed certificate with name mismatch | Low (2) | Accepted (lab environment) |

3 High, 5 Medium and 3 Low findings. The risk register has the evidence, fix and re-test result for each one.

## Documents

| Document | What it is |
|---|---|
| [`scope/scope-statement.md`](scope/scope-statement.md) | Scenario, scope, rules of engagement, success metrics and limitations |
| [`inventory/asset-inventory.md`](inventory/asset-inventory.md) | The assets, services and planted-versus-existing findings |
| [`reports/baseline-assessment-report.md`](reports/baseline-assessment-report.md) | The state before any fixes, with the scanner results |
| [`risk-register/risk-register.md`](risk-register/risk-register.md) | The 11 findings: ratings, evidence, status, re-test results and residual risks |
| [`remediation/remediation-plan.md`](remediation/remediation-plan.md) | What was changed for each finding, how it was validated, and the evidence files |
| [`reports/final-security-report.md`](reports/final-security-report.md) | The before/after results, written for the IT manager |
| [`worklog.md`](worklog.md) | Dated log of the work and the decisions made |

Start with the final report for the outcome, then the risk register for the detail.

## Evidence

Evidence is stored under `evidence/` in dated folders. Each folder has a SHA-256 hash file (`sha256*`), so each file can be checked against the fingerprint taken on the day.

| Folder | Contents |
|---|---|
| `2026-10-28`, `2026-10-29`, `kali-evidence-2026-10-29` | Baseline: checklist, Lynis, Nmap, Nikto, permissions and listings |
| `2026-11-03` | Fix evidence for F-01 to F-06 |
| `2026-11-05`, `2026-11-05-kali` | Fix evidence for F-07 to F-10, from the server and from Kali |
| `2026-11-05-after-server`, `2026-11-05-after-kali` | Re-test: checklist, Lynis, Nmap and Nikto after the fixes |

Two Kali files keep the names they were given while the fixes were in progress: `f08-after.txt` belongs to the banner finding (F-09), and the `f09-*.txt` files belong to the directory-listing finding (F-08). They were not renamed, so their hashes still match.

### Verify the evidence

On Linux, macOS or Git Bash, from inside an evidence folder:

```bash
cd evidence/2026-11-05
sha256sum -c sha256-server-2026-11-05.txt
```

Every line should end in `OK`.

On Windows PowerShell, from the `evidence` folder:

```powershell
Get-ChildItem -Directory -Recurse | ForEach-Object {
    $dir = $_.FullName
    Get-ChildItem -Path $dir -Filter 'sha256*' -File | ForEach-Object {
        "--- $($_.Name) in $dir ---"
        Get-Content $_.FullName | ForEach-Object {
            if ($_ -match '^\s*([0-9a-fA-F]{64})\s+\*?(.+?)\s*$') {
                $expected = $Matches[1].ToLower(); $file = $Matches[2]
                $path = Join-Path $dir $file
                if (Test-Path $path) {
                    $actual = (Get-FileHash -Algorithm SHA256 $path).Hash.ToLower()
                    "{0}  {1}" -f $(if ($actual -eq $expected) {'OK      '} else {'MISMATCH'}), $file
                } else { "MISSING   $file" }
            }
        }
    }
}
```

The `.gitattributes` file in this repository stops Git from changing line endings in the evidence files, because converting them would change their hashes.

## Repository layout

```
security-baseline-lab/
├── README.md
├── worklog.md
├── .gitattributes
├── scope/            scope-statement.md
├── inventory/        asset-inventory.md
├── reports/          baseline-assessment-report.md, final-security-report.md
├── risk-register/    risk-register.md
├── remediation/      remediation-plan.md
└── evidence/         dated folders with hashed evidence files
```

## Limitations and disclosures

- One simulated server on an isolated network; the results do not describe a production system.
- The 16 controls are my own checklist, modelled on the CIS Ubuntu Linux and CIS Apache HTTP Server 2.4 benchmarks. This is not an official CIS benchmark assessment.
- The after-fix checklist ran with a script reconstructed from the baseline output, because the original commands were not kept as a script. The output format matches the baseline.
- The weak password on `testuser` was never tested directly, because no scanner detected it. The account was removed.
- The after-fix full-port Nmap scan used `--max-retries 1`, because the firewall drops packets to closed ports and the default settings are very slow. The baseline scan did not use that option.
- Nikto reported one false positive after the fixes (`X-Content-Type-Options` "not set"), although the header was verified on four request types. The cause was not determined.
- The self-signed certificate, the loaded directory-listing module and the deferred non-security updates are accepted residual risks, rated Low.

## Tools

Lynis 3.1.6, Nmap 7.99, Nikto 2.6.0, fail2ban, UFW, curl, Kali Linux, VirtualBox.

## Author

Marshel Mburu Macharia, aspiring cybersecurity professional, Nairobi.
[LinkedIn](https://www.linkedin.com/in/marshel-macharia-a8a508327/)  