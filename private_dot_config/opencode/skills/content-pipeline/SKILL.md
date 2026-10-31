---
name: content-pipeline
description: Technical content generation; blog posts, docs, HN/Reddit announcements, and changelog entries
compatibility: opencode
metadata:
  audience: agents
  workflow: marketing
---

## What I do

Generate technical content that is technically accurate and written for
the right audience. Each output type has a different structure, tone,
 and audience; this skill encodes those differences.

## Output types

### Blog post
- **Audience**: practitioners who will use the thing
- **Structure**: problem → why existing solutions don't work → your
  approach → how it works (with code) → limitations (honest) → link
- **Tone**: direct, no fluff, no "in today's fast-paced world"
- **Code**: real code, not pseudocode; every snippet must compile/run
- **Length**: as long as needed, no shorter

### HN / Reddit announcement
- **Audience**: skeptical technical readers who will check your claims
- **Title**: what it does, not what you think about it ("Show HN: I
  built X that does Y" not "Introducing the revolutionary X")
- **Body**: the problem, the approach, one demo/ GIF link, "I'd love
  feedback"; nothing else
- **Length**: < 150 words for the body (HN readers scroll)
- **NEVER**: marketing language, superlatives, "game-changing",
  "revolutionary", or the word "simply"

### Changelog entry
- **Audience**: users deciding whether to upgrade
- **Format**: Keep a Changelog; Added / Changed / Fixed / Removed
- **Rule**: every entry describes the user-visible change, not the
  implementation ("Fixed: MCP server auth" not "Refactored auth flow")

### Documentation page
- **Audience**: someone who has the thing installed and wants to use
  this specific feature
- **Structure**: what it does → prerequisites → steps → what success
  looks like → what to do if it fails

## Rules

1. Every claim must be backed by something in the repo (code, test,
   benchmark). If you can't point to it, don't claim it.
2. No superlatives without evidence. "Fast" needs a benchmark number.
3. Limitations are a feature; they set expectations and reduce support.
4. The reader is smart and skeptical. Write for them.
