---
name: db-migration
description: Database migration safety — pre-flight checks, rollback planning, data-loss detection
compatibility: opencode
metadata:
  audience: agents
  workflow: full-stack
---

## What I do

Review database migrations for safety before they run against any
environment with real data. Checks for: data loss, locking, rollback
plan, and the difference between what the migration file says and what
it actually does to the schema.

## Workflow

1. **Read the migration** — understand what DDL/DML it executes
2. **Data loss check** — does it DROP a table, COLUMN, or CONSTRAINT?
   Does it TRUNCATE? Does it change a column type (implicit cast may
   lose data)?
3. **Locking check** — does it take an exclusive lock? (ALTER TABLE ADD
   COLUMN without a default in Postgres < 11 = full table scan + lock)
4. **Rollback plan** — is there a down migration? Has it been tested?
   Can it be run without data loss?
5. **Order of operations** — deploy code FIRST, then migration, then
   new code? Or migration + code atomically? The wrong order = downtime
6. **Dependencies** — does anything else (views, triggers, app code)
   depend on the schema being changed?

## Red flags

- `DROP TABLE` / `DROP COLUMN` without a documented rollback
- `ALTER TABLE ... ALTER COLUMN ... TYPE` on a large table (locks + rewrite)
- Adding a `NOT NULL` column without a `DEFAULT` on a large table
- Migration that mixes schema changes with data backfill (split them)
- No down migration file
- Migration that assumes a specific number of rows (will fail if the
  environment differs)

## Output

A table: migration | operation | risk (none/low/medium/high) | lock
required | rollback possible | data loss. Then a go/no-go
recommendation with the specific risk for each flagged item.

## What NOT to do

- Never approve a migration you haven't read line by line — comment
  lines can hide destructive DDL.
- Never approve a migration for production without testing it on a
  staging environment with production-like data volume.
- Never assume the ORM's migration generator produces safe DDL —
  it optimizes for the framework, not for zero-downtime deploys.
