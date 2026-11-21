# Upstream issue draft (held for filing) — continuuwuity

## Title
DM room forward extremities stop advancing: new events accepted (200)
but never reach /sync or /messages on any client

## Environment
- continuuwuity v26.9.1 (docker.io image), single-instance, TrueNAS
- Room: `!IEwsBK9qdYhPcm6QA668Ek9HAPIm9Mucc9LvPQltn3g` (v11 encrypted DM, 2 members across federation)

## Symptoms
1. Timeline tip frozen at T0 (~5.7h before detection). Events accepted
   after T0 return 200 + event ids via /send (txn receipts verified)
   but never appear in /sync (fresh bootstrap) or /messages dir=b —
   on ALL clients, all sessions, incl. the senders' own echo.
2. `docker restart` recomputed the same stuck state (no change).
3. Forward walk from the tip (dir=f from dir=b end token) returns
   0 chunks — server believes the timeline ends at T0.
4. A session holding a PRE-T0 sync token receives ALL post-T0 events
   via incremental /sync — data is persisted and decryptable; only
   tip-based reads are wedged.
5. Other rooms on the same server advance normally (room-scoped).

## Suspected trigger
Four concurrent local sessions (different devices, same account) sent
messages to the room within one minute window (tui + gui + listener +
probe). Suspect concurrent /send created a fork the extremity
resolution never merged.

## Requested
- Extremity reconciliation pass for affected rooms (admin command or
  automatic on restart would both help).
- Admin diagnostic to inspect forward extremities per room.

## Local evidence
dir=f from tip: 0 chunks; pre-T0 incremental sync streams all events
(incl. sender echoes, all decrypting correctly via vodozemac).
