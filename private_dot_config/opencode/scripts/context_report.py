#!/usr/bin/env python3
"""Report agent context cost from the OpenCode session database.

Answers: which sessions, tools, and calls are eating the context window?
Reads ~/.local/share/opencode/opencode.db (read-only).

Usage:
  context_report.py sessions [--hours H] [--limit N]
  context_report.py tools    [--hours H] [--limit N]
  context_report.py call --session <id> [--top N]

Notes:
  * token counts come from assistant message records (input/output/reasoning
    /cache) and are the provider's numbers, not estimates.
  * tool output bytes are exact (UTF-8 length of the tool part output); the
    ~tokens column is bytes/4, the usual English/code ratio.
Stdlib only.
"""
from __future__ import annotations

import json
import os
import sqlite3
import sys
import time

DB = os.path.expanduser("~/.local/share/opencode/opencode.db")


def connect(path):
    con = sqlite3.connect(f"file:{path}?mode=ro", uri=True, timeout=10)
    con.row_factory = sqlite3.Row
    return con


def load_messages(con, since_ms):
    for row in con.execute(
        "select session_id, data from message where time_created >= ?", (since_ms,)
    ):
        try:
            d = json.loads(row["data"])
        except json.JSONDecodeError:
            continue
        if d.get("role") != "assistant":
            continue
        yield row["session_id"], d


def session_titles(con):
    titles = {}
    try:
        for row in con.execute("select id, title from session_v2"):
            titles[row["id"]] = row["title"]
    except sqlite3.Error:
        pass
    return titles


def cmd_sessions(con, since_ms, limit):
    agg = {}
    for sid, d in load_messages(con, since_ms):
        t = d.get("tokens") or {}
        a = agg.setdefault(sid, {"in": 0, "out": 0, "reason": 0,
                                 "cache_r": 0, "cache_w": 0, "cost": 0.0,
                                 "msgs": 0})
        a["in"] += t.get("input", 0)
        a["out"] += t.get("output", 0)
        a["reason"] += t.get("reasoning", 0)
        cache = t.get("cache") or {}
        a["cache_r"] += cache.get("read", 0)
        a["cache_w"] += cache.get("write", 0)
        a["cost"] += d.get("cost", 0) or 0
        a["msgs"] += 1
    titles = session_titles(con)
    print(f"{'session':26s} {'msgs':>5s} {'in':>9s} {'cache_r':>9s} "
          f"{'out':>8s} {'cost$':>7s}  title")
    for sid, a in sorted(agg.items(), key=lambda kv: -(kv[1]["in"] + kv[1]["cache_r"]))[:limit]:
        title = (titles.get(sid) or "")[:44]
        print(f"{sid[:26]:26s} {a['msgs']:5d} {a['in']:9d} {a['cache_r']:9d} "
              f"{a['out']:8d} {a['cost']:7.2f}  {title}")
    tot_in = sum(a["in"] for a in agg.values())
    tot_c = sum(a["cache_r"] for a in agg.values())
    print(f"\n{tot_in} input + {tot_c} cache-read tokens across {len(agg)} sessions "
          f"(cache hit {tot_c / max(1, tot_in + tot_c):.0%})")


def cmd_tools(con, since_ms, limit):
    stats = {}
    q = ("select p.session_id, p.data from part p where p.time_created >= ? "
         "and p.data like '%\"type\":\"tool\"%'")
    for row in con.execute(q, (since_ms,)):
        try:
            d = json.loads(row["data"])
        except json.JSONDecodeError:
            continue
        if d.get("type") != "tool":
            continue
        tool = d.get("tool", "?")
        state = d.get("state") or {}
        out = state.get("output")
        if not isinstance(out, str):
            out = json.dumps(out or "")
        s = stats.setdefault(tool, {"calls": 0, "bytes": 0, "max": 0})
        s["calls"] += 1
        s["bytes"] += len(out.encode())
        s["max"] = max(s["max"], len(out.encode()))
    print(f"{'tool':24s} {'calls':>6s} {'total KB':>10s} {'max KB':>8s} {'~tokens':>10s}")
    for tool, s in sorted(stats.items(), key=lambda kv: -kv[1]["bytes"])[:limit]:
        print(f"{tool[:24]:24s} {s['calls']:6d} {s['bytes']/1024:10.0f} "
              f"{s['max']/1024:8.0f} {s['bytes']//4:10d}")
    total = sum(s["bytes"] for s in stats.values())
    print(f"\ntotal tool output: {total/1024/1024:.1f} MB (~{total//4} tokens) "
          f"over {sum(s['calls'] for s in stats.values())} calls")


def cmd_call(con, session_id, top):
    rows = []
    q = ("select data from part where session_id = ? "
         "and data like '%\"type\":\"tool\"%' order by time_created")
    for row in con.execute(q, (session_id,)):
        try:
            d = json.loads(row["data"])
        except json.JSONDecodeError:
            continue
        if d.get("type") != "tool":
            continue
        state = d.get("state") or {}
        inp = state.get("input") or {}
        out = state.get("output")
        if not isinstance(out, str):
            out = json.dumps(out or "")
        rows.append((len(out.encode()), d.get("tool", "?"),
                     str(inp)[:110], out[:160].replace("\n", " ")))
    rows.sort(reverse=True)
    print(f"{'bytes':>8s} {'tool':12s} input → output head")
    for n, tool, inp, head in rows[:top]:
        print(f"{n:8d} {tool[:12]:12s} {inp} → {head}")
    print(f"\n{len(rows)} tool calls, {sum(r[0] for r in rows)/1024:.0f} KB total")


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    mode = argv[1]
    args = argv[2:]
    db = DB
    if "--db" in args:
        db = args[args.index("--db") + 1]
    hours = 24.0
    if "--hours" in args:
        hours = float(args[args.index("--hours") + 1])
    limit = 15
    if "--limit" in args:
        limit = int(args[args.index("--limit") + 1])
    if "--top" in args:
        limit = int(args[args.index("--top") + 1])
    if not os.path.exists(db):
        print(f"database not found: {db}", file=sys.stderr)
        return 2
    con = connect(db)
    since = int((time.time() - hours * 3600) * 1000)
    if mode == "sessions":
        cmd_sessions(con, since, limit)
    elif mode == "tools":
        cmd_tools(con, since, limit)
    elif mode == "call":
        if "--session" not in args:
            print("call mode needs --session <id>", file=sys.stderr)
            return 2
        cmd_call(con, args[args.index("--session") + 1], limit)
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
