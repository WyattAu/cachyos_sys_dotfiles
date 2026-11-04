#!/usr/bin/env python3
"""Audit agent skills for retrieval quality, size, and duplication.

Checks every SKILL.md under the given roots and reports:
  - frontmatter presence, name/dir match, description trigger quality
  - size budget (words/lines), estimated load cost in tokens
  - progressive disclosure (references/ for long skills)
  - duplicate names and near-duplicate descriptions
  - projected skills (PROVENANCE.yml) flagged as do-not-edit

Usage:
  skill_audit.py [ROOT ...] [--json] [--max-words N] [--quiet]

Exit codes: 0 clean, 1 findings (errors), 2 usage error.
Stdlib only; no third-party dependency.
"""
from __future__ import annotations

import json
import os
import re
import sys
from difflib import SequenceMatcher

FM = re.compile(r"\A---\s*\n(.*?)\n---\s*\n", re.S)
TRIGGER = re.compile(
    r"use (this |it )?(when|for|before|after)|trigger|load (this|when)|"
    r"when the user|does not:|do not use",
    re.I,
)
DEFAULT_MAX_WORDS = 2000
GOOD_DESC = (120, 500)


def parse(text: str):
    m = FM.match(text)
    if not m:
        return None, text
    meta, key = {}, None
    for line in m.group(1).splitlines():
        km = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if km:
            key = km.group(1)
            meta[key] = km.group(2).strip().strip("\"'")
        elif key and line[:1] in (" ", "\t"):
            meta[key] = (meta.get(key, "") + " " + line.strip()).strip()
    return meta, text[m.end():]


def find_skills(roots):
    for root in roots:
        for dp, dn, fn in os.walk(root):
            dn[:] = [d for d in dn if d not in {".git", "node_modules"}]
            if "SKILL.md" in fn:
                yield os.path.join(dp, "SKILL.md")


def audit(roots, max_words):
    rows, errors, warnings = [], [], []
    seen_names = {}
    for path in find_skills(roots):
        text = open(path, encoding="utf-8", errors="replace").read()
        meta, body = parse(text)
        dirname = os.path.basename(os.path.dirname(path))
        words = len(body.split())
        est_tokens = max(1, len(text) // 4)
        row = {
            "path": path,
            "dir": dirname,
            "name": None,
            "desc_chars": 0,
            "words": words,
            "est_tokens": est_tokens,
            "problems": [],
        }
        if meta is None:
            row["problems"].append("missing frontmatter")
            errors.append(f"{path}: missing frontmatter")
            rows.append(row)
            continue
        name = meta.get("name", "")
        desc = meta.get("description", "")
        row["name"], row["desc_chars"] = name, len(desc)
        if not name:
            errors.append(f"{path}: frontmatter has no name")
            row["problems"].append("no name")
        elif name != dirname:
            warnings.append(f"{path}: name '{name}' != directory '{dirname}'")
            row["problems"].append("name/dir mismatch")
        if name in seen_names:
            errors.append(f"{path}: duplicate name '{name}' (also {seen_names[name]})")
            row["problems"].append("duplicate name")
        else:
            seen_names[name] = path
        if len(desc) < GOOD_DESC[0]:
            warnings.append(f"{path}: description short ({len(desc)} chars)")
            row["problems"].append("short description")
        elif len(desc) > GOOD_DESC[1]:
            warnings.append(f"{path}: description long ({len(desc)} chars)")
            row["problems"].append("long description")
        if not TRIGGER.search(desc):
            warnings.append(f"{path}: description has no trigger phrasing")
            row["problems"].append("no triggers")
        if words > max_words:
            errors.append(f"{path}: {words} words > {max_words} budget")
            row["problems"].append("over word budget")
        refdir = os.path.join(os.path.dirname(path), "references")
        if words > 1200 and not os.path.isdir(refdir):
            warnings.append(f"{path}: long skill without references/")
            row["problems"].append("no progressive disclosure")
        if os.path.exists(os.path.join(os.path.dirname(path), "PROVENANCE.yml")):
            row["projected"] = True
        rows.append(row)
    # near-duplicate descriptions
    for i, a in enumerate(rows):
        for b in rows[i + 1:]:
            if not a["name"] or not b["name"]:
                continue
            da = open(a["path"], encoding="utf-8", errors="replace").read()[:600]
            db = open(b["path"], encoding="utf-8", errors="replace").read()[:600]
            ratio = SequenceMatcher(None, da, db).ratio()
            if ratio > 0.8:
                warnings.append(
                    f"near-duplicate: {a['name']} ~ {b['name']} ({ratio:.2f})"
                )
    return rows, errors, warnings


def main(argv):
    roots = [a for a in argv[1:] if not a.startswith("--")]
    if not roots:
        roots = [os.path.expanduser("~/.config/opencode/skills")]
    max_words = DEFAULT_MAX_WORDS
    if "--max-words" in argv:
        max_words = int(argv[argv.index("--max-words") + 1])
    rows, errors, warnings = audit(roots, max_words)
    if "--json" in argv:
        print(json.dumps({"skills": rows, "errors": errors, "warnings": warnings},
                         indent=2))
    else:
        rows.sort(key=lambda r: -r["est_tokens"])
        print(f"{'skill':32s} {'words':>6s} {'~tok':>6s}  problems")
        for r in rows:
            print(f"{(r['name'] or r['dir'])[:32]:32s} {r['words']:6d} "
                  f"{r['est_tokens']:6d}  {', '.join(r['problems']) or '-'}")
        total = sum(r["est_tokens"] for r in rows)
        print(f"\n{len(rows)} skills, ~{total} tokens if all loaded; "
              f"largest {max((r['est_tokens'] for r in rows), default=0)}")
        for w in warnings:
            print(f"WARN  {w}")
        for e in errors:
            print(f"ERROR {e}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
