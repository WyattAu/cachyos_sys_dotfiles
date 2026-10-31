---
name: secret-scan
description: Scan repos and Docker images for leaked secrets and CVEs using gitleaks and trivy
compatibility: opencode
metadata:
  audience: agents
  workflow: security
---

## What I do

Run gitleaks (secret detection) and trivy (CVE scanning) against repos
and Docker images, then triage the findings. These are native binaries
installed fleet-wide via pacman; no MCP server needed, just shell.

## Workflow

### Secret scanning (gitleaks)

```sh
gitleaks detect --source <repo> --report-format json --report-path /tmp/leaks.json
```

Triage each finding:
- **Real secret**; rotate immediately (the leak is already in git
  history; deleting the file does not help)
- **False positive**; add to `.gitleaksignore` with the commit SHA
- **Test fixture / placeholder**; safe to ignore; add
  `gitleaks:allow` inline comment

### Container scanning (trivy)

```sh
trivy image --severity HIGH,CRITICAL <image:tag>
trivy fs --severity HIGH,CRITICAL <path>
```

Triage:
- **Fix available**; bump the base image or dependency
- **No fix available**; assess exposure: is the vulnerable code path
  reachable? Document the risk acceptance
- **Base image CVE**; check if a newer tag exists; if not, note it

## Decision rules

- A secret in git history requires rotation, not deletion. Deleting the
  file from HEAD does not remove it from previous commits.
- gitleaks findings in test fixtures or documentation examples are
  false positives; allowlist them, do not rotate.
- trivy findings in a stdio-only container (no published ports) with
  network CVEs have no reachable attack surface. Document the exposure
  analysis.

## What NOT to do

- Never print a secret value in a report or commit message. The
  finding's file path and line number are enough.
- Never rotate a key without confirming the old one is no longer needed
  by another service.
