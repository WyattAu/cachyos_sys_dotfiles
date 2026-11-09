# Context economy (enforced every turn)

- Locate before read: `grep -n` the symbol, then read ±40 lines. No full-file dumps.
- Cap every tool output: `| head -40`, `| tail -20`, `--jq`, `wc -l`. Filter first, widen once.
- Batch independent tool calls in one block. Serialize only real dependencies.
- Delegate noise (broad searches, huge logs) to a subagent; require ≤15 lines + `file:line` pointers.
- Durable state goes to files (plan ledger, handoff notes). Re-read from files, not context.
- Answers are deltas: verdict first, changed lines + 2 context lines. No re-pasting, no re-summarizing.
- Every response should be the shortest that preserves the decision.
