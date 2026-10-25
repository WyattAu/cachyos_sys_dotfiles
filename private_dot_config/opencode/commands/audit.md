Run a full security audit on this repository or the specified target.

Use the fleet's security tooling (all installed natively):

1. **Secrets**: `gitleaks detect --source . --report-format json --report-path /tmp/leaks.json`
   - Triage each finding: real (rotate) vs false positive (allowlist)
2. **CVEs**: `trivy fs --severity HIGH,CRITICAL .` (or `trivy image` for containers)
   - Check if fixes exist; assess exposure for unfixable ones
3. **Reversecore static analysis**: if auditing a binary, use the
   `re-triage` skill workflow instead
4. **OSINT**: if auditing a domain/IP, use the osint MCP server's
   keyless tools (DNS, WHOIS, crt.sh, Wayback)

Output: a prioritized findings table (CRITICAL → HIGH → MEDIUM → LOW → INFO)
with the evidence for each, the fix, and the exposure assessment.
