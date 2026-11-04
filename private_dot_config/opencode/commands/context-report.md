Report where this machine's agent context budget went, from the OpenCode session DB.

Arguments (optional): `sessions`, `tools`, or `call <session-id>`. Default: `tools --hours 24`.

Run:

```bash
python3 ~/.config/opencode/scripts/context_report.py ${ARGUMENTS:-tools --hours 24}
```

Interpretation:

| Observation | Action |
|---|---|
| one tool dominates total bytes | cap it: `head`, `--jq`, grep counts, or delegate |
| cache-read share < 60% | context is churning; stabilise prompt prefix, shorten turns |
| a single call > 2% of context | that call was a whole-file or whole-log read |
| sessions with high output tokens | cut narration; verdict + deltas only |

Rules:
- The report is read-only; never write to the session DB.
- Quote numbers, not impressions: bytes, tokens, cache hit ratio.
- If the window is empty, widen `--hours` or check the newest record timestamp
  the script prints; the DB path can be overridden with `--db`.
