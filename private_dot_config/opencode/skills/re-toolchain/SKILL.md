---
name: RE Toolchain
description: >
  Use when analyzing, disassembling, or decompiling binaries (ELF, PE,
  Mach-O, firmware, malware, crackmes, CTF reversing). Covers the
  radare2 (r2mcp) and Ghidra (GhidraMCP) MCP servers, when to use which,
  and safe-analysis workflow.
---

# Reverse Engineering Toolchain

Two MCP servers are available for binary analysis. Choose based on depth
needed, not habit:

| | `radare2` (r2mcp) | `ghidra` (GhidraMCP) |
|---|---|---|
| Startup | Instant, no prerequisites | Ghidra must be open with a program loaded |
| Best for | Triage, headers, strings, quick decompile, ROP, crypto constants | Deep decompilation, cross-references, renaming, structured re |
| Emulation | Rizin RzIL/ESIL tools (safe, no execution) | P-code (via Ghidra) |

Tool names are prefixed `radare2_` and `ghidra_` (under Code Mode:
`tools.radare2.*` / `tools.ghidra.*`).

## Hard rules

1. **Never execute an untrusted binary.** Use static tools or ESIL
   emulation. If dynamic analysis is unavoidable, ask the user first and
   run inside a disposable container (`docker run --rm -it --network none
   -v "$PWD":/work`) — never on the host.
2. **Ghidra is not always running.** If `ghidra_*` tools fail with a
   connection error, the Ghidra GUI is closed or has no program open.
   Tell the user to run `ghidraRun`, open the binary in CodeBrowser, and
   confirm the GhidraMCPPlugin is enabled (File → Configure → Developer).
   Do not retry more than once; fall back to `radare2`.
3. **Triage before depth.** Run the r2 one-shot triage tool first; only
   escalate to Ghidra for functions that deserve real study.

## Workflow

1. **Identify**: `file`/`r2 -qc "iI" <bin>` basics, then r2mcp's binary
   info tool — format, arch, bits, compiler, protections (PIE/RELRO/NX).
2. **Triage (r2)**: strings → imports/exports → entry points → function
   list after auto-analysis. Look for crypto constants, network APIs,
   suspicious import clusters (`exec`, `ptrace`, `mmap` + `chmod +x`).
3. **Decompile**: start with r2's per-function decompiler for speed.
   Switch to Ghidra for functions with dense control flow or where you
   need xrefs to data/strings.
4. **Name as you learn**: apply renames in the tool you're working in
   (r2mcp rename tools, or Ghidra's). Renaming in Ghidra persists in the
   project; prefer Ghidra for long-running analysis.
5. **Emulate, don't run**: for crackme/keygen logic, use the ESIL/RzIL
   tools to evaluate code paths with crafted inputs.
6. **Report**: summarize entry → key functions → IO (args/files/network)
   → verdict. Reference addresses as `sym.name @ 0xaddr`.

## Environment notes

- Backends live on PATH: `radare2`, `rizin` (pacman), `r2mcp` via
  `r2pm -r r2mcp`, `ghidra-mcp` (uv tool, v2 CLI from the GhidraMCP
  release wheel).
- The fleet r2mcp config is sandboxed to `~/dev` (`-s`, single dir —
  repeated `-s` flags replace rather than add, and colon lists break
  opening entirely). If a caller points at a binary elsewhere, say so
  and ask them to copy it into `~/dev/sandbox` — do not suggest
  removing the sandbox. The dangerous `run_*` tools are disabled and
  sandbox mode blocks the exec/socket grains; treat both as permanent.
- The Ghidra extension sits in
  `~/.ghidra/.ghidra_<ver>_PUBLIC/Extensions/GhidraMCP/`; its backend
  binds `127.0.0.1:8080` in GUI mode.
- Headless escape hatch: `ghidra-mcp --headless --binary <path>` runs
  Ghidra in-process (needs the pyghidra extra + `GHIDRA_INSTALL_DIR`).
  Prefer this only when the user asks for fully non-GUI analysis.
- Firmware/other-arch targets: check r2's arch list (`-a ?`) before
  assuming x86; use Ghidra for exotic loaders it supports that r2
  mishandles.
