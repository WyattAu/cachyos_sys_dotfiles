Binary triage using the reversecore MCP server.

Target: $ARGUMENTS

The sample must be in ~/dev/sandbox/ (the reversecore server is
sandboxed there). If it's not, copy it first:
  cp <source> ~/dev/sandbox/<name>

Use the re-triage skill workflow (4 phases, never skip Phase 1):

Phase 1 — Identify (all of these, in order):
  Radare2_open_file → Radare2_analyze → Radare2_list_functions →
  Radare2_list_imports → Radare2_list_strings → Radare2_list_sections →
  Radare2_list_entrypoints

Phase 2 — Capability detection:
  run_capa → run_capa_quick → unpack if packed

Phase 3 — IOC extraction:
  extract_iocs → cross-reference against known-good

Phase 4 — Decision:
  Benign / Suspicious / Malicious, with evidence for each classification.

Decision rules:
- Multiple entrypoints + high entropy = packed. Unpack first.
- Networking imports + URLs + no purpose = exfiltration or C2.
- write_process_memory + create_remote_thread = injection. Always malicious.
- Never run outside the detonate container. Never conclude from strings alone.
