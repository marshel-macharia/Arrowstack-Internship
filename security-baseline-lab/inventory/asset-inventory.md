# Asset Inventory

## Systems
| ID | Asset | Type | OS / software | Address | Role | Criticality | Data sensitivity |
|---|---|---|---|---|---|---|---|
| A-01 | apache-web-01 | Server VM | Ubuntu Server 26.04 LTS, Apache 2.4.66 | 192.168.208.10 | Public web server | High | Medium |
| A-02 | Kali | Workstation VM | Kali Linux 2026.2 | 192.168.208.30 [confirm] | Assessor workstation | Low | Low |

## Accounts on apache-web-01
| Account | Type | Status |
|---|---|---|
| root | System | Authorized (SSH key-only) |
| marshel | Administrator | Authorized |
| splunkfwd | Service account [confirm: Splunk forwarder] | Authorized, documented |
| testuser | Local user | Unauthorized (finding A3) |