---
name: re-triage
description: Binary triage workflow using reversecore MCP — static analysis, capability detection, IOC extraction, and containment decisions
compatibility: opencode
metadata:
  audience: agents
  workflow: security
  opencode/slash: "true"
---

## What I do

Run a structured binary triage using the reversecore MCP server (151
tools): identify what a binary does, whether it's dangerous, and what
to do about it. Every step builds on the previous — don't skip ahead.

## Prerequisites

- Sample must be in `~/dev/sandbox/` (the reversecore MCP is
  sandboxed to that directory — see the `reversecore` server config).
- Radare2 must be installed (`r2 --version`).

## Workflow

### Phase 1: Identify (never skip)

1. `Radare2_open_file` with the sample path
2. `Radare2_analyze` at the appropriate level (aaa for full, aaaa for deep)
3. `Radare2_list_functions` — count and look for suspicious names
4. `Radare2_list_imports` — look for dangerous APIs (CreateRemoteThread,
   WriteProcessMemory, WinExec, socket/connect, etc.)
5. `Radare2_list_strings` — look for URLs, IPs, registry keys, file paths,
   base64 blobs, crypto constants
6. `Radare2_list_sections` — check entropy (high entropy = packed/encrypted)
7. `Radare2_list_entrypoints` — multiple entrypoints is suspicious

### Phase 2: Capability detection

8. `run_capa` — MITRE ATT&CK mapping (what CAN this binary do?)
9. `run_capa_quick` — faster, uses a rule subset
10. If packed: `binwalk` or `die` to identify the packer, then unpack
    before deeper analysis

### Phase 3: IOC extraction

11. `extract_iocs` — pull IPs, URLs, domains, hashes, registry keys
12. Cross-reference IOCs: check against known-good before flagging

### Phase 4: Decision

Classify as one of:
- **Benign** — explain why (expected imports, no suspicious strings, no
  capability flags)
- **Suspicious** — list specific indicators with evidence
- **Malicious** — list ATT&CK techniques observed, IOCs, and
  recommended containment

## Decision rules

- Multiple entrypoints + high-entropy sections = likely packed. Unpack
  before concluding.
- Networking imports + string URLs + no legitimate purpose = likely
  exfiltration or C2.
- Single function, tiny binary, no imports = likely a shellcode stub.
  Escalate to dynamic analysis.
- `write_process_memory` + `create_remote_thread` = injection. Always
  malicious in a legitimate binary.

## What NOT to do

- Never run the sample outside the detonation container.
- Never conclude from strings alone — strings can be planted.
- Never skip Phase 1 even if the filename looks benign.
