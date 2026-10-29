# Work Log

## 2026-10-28
- Selected apache-web-01 (target) and Kali (assessor)
- Took snapshot apache-web-01-HARDENED-final
- Introduced intentional misconfigurations (banners, directory listing, 777 web root, UFW off, extra weak-password account)
- Took snapshot apache-web-01-UNHARDENED-baseline
- Captured evidence, hashed with SHA-256, copied to the host and verified
- Ran the 16-control baseline checks: 6 pass, 10 fail
- Committed the evidence to the repo (commit d1d23d4)
- Wrote scope statement and asset inventory