---
name: state-machine-audit
description: Use when asked to find, document or audit an app's state machines, lifecycles or status fields, or to hunt for invalid states and transitions, including ones reached through retries, duplicate webhooks, races or concurrent requests.
---

# State machine audit

Every status field, flag combination and multi-step flow is a state machine,
whether or not the code says so. The audit makes each one explicit, proves
which invalid states the code can really reach, and fixes them test-first.

The output is one living document, one issue per root cause, and one commit
per issue. A bug counts only when a test is seen failing on the unfixed code,
with that red output recorded in its issue.

## Steps

1. **Inventory.** List every machine, explicit and implicit, using the
   hunting list below. Done when every persisted field that changes after
   creation, and every multi-step flow, belongs to a machine or is noted as
   stateless.
2. **Document.** Write `docs/state-machines.md` in the shape below (or the
   project's docs folder if it has one), in the repo. Done when every machine
   has states, invariants and a full transition table, each row citing the
   file and function (`src/orders.ts` `ship()`), which survive edits better
   than line numbers.
3. **Hunt.** For each machine, try to break each invariant through every
   entry point, then again through retries, redelivery, timeouts, crashes
   between steps, and two callers interleaving at each `await` or I/O
   boundary. Done when each candidate is either **confirmed** (a test seen
   failing on the unfixed code) or **rejected** with the reason it can't be
   reached. Code only tests call, unused exports and corrupt-data branches
   are rejected unless a real caller reaches them.
4. **Triage.** Label confirmed bugs by impact: **P1** money or data lost or
   duplicated, **P2** a stuck or corrupt record, **P3** a wrong but
   recoverable state, **P4** cosmetic. Group bugs that share a root cause into
   one issue, which quotes the red test output as its evidence. File issues in
   the project's tracker (`gh issue create` when the repo is on GitHub),
   otherwise as `docs/issues/NNN-slug.md`. Issues are a record of what was
   found, so leave their line numbers as they were.
5. **Checkpoint.** List each fix that changes intended behaviour (a business
   rule, a public API, a removed export, a new state) and ask the user about
   all of them in one message before applying any. When nobody can answer, prefer the option that loses no money
   or data, then the one that leaves a stuck record a person can see over a
   silent duplicate, and record it under Decisions.
6. **Fix.** Order issues so that one another depends on goes first, then by
   priority. Per issue: regression test red on the old code, fix, test green,
   committed suite plus this test green, update the document, then one commit
   with test and fix together, referencing the issue. A deferred issue still
   commits its test, marked skipped or todo with the issue number, so the
   suite stays green. A new invalid path that an earlier fix opens up is a
   new issue, confirmed red on the code as it is now, naming the fix that
   exposed it. Done when every issue is fixed or deferred with a reason.

## Hunting list (implicit machines)

- Booleans or nullable fields that only make sense in combination
  (`isPaid` + `shippedAt`, `deletedAt` + `status`). Enumerate the combinations.
- Enums or strings named status, state, phase, step, stage, mode.
- Fields written in more than one place, especially across services or jobs.
- Webhooks, queue consumers, cron jobs and retries: each one is a transition
  that can arrive twice, late or out of order.
- Read, then `await`, then write: a lost update unless guarded by a version,
  lock or conditional write.
- An intermediate state set before an external call (`charging`, `sending`):
  check what happens when the call throws, times out or the process dies.
- UI and client state: loading, error, retry, optimistic updates,
  double-submit, back button, two tabs.
- Caches, sessions, tokens and feature flags with their own lifecycle.

## Document shape

`docs/state-machines.md` always describes the code as it is now. Git keeps the
history, so replace tables when the code changes.

```markdown
# State machines

## <Machine name>
Where: `src/orders.ts`, `status` field. Concurrency guard: <none, version, lock, ...>

States: pending, paid, shipped, cancelled.

Invariants:
- I1. shipped implies paid at some point (`paidAt` set).

| From | Event or caller | Guard | To | Code |
|---|---|---|---|---|
| pending | checkout() | status = pending | charging | `src/orders.ts` `checkout()` |

Issues: #3 P1 fixed, #5 P2 deferred (or "none confirmed")

## Rejected candidates
- <candidate>: <why it can't be reached>

## Decisions
- <behaviour chosen without the user, and why>

## Known gaps
- <reachable problem deliberately not fixed, and why>
```

## Common mistakes

| Mistake | Instead |
|---|---|
| Reporting a bug from reading alone | Show it with a test that fails on the unfixed code |
| One commit fixing several issues | One commit per issue, so each can be reviewed and reverted |
| Rolling back an intermediate state after an unknown outcome (timeout) | Keep it and reconcile, or the retry may charge twice |
| Quietly changing a business rule | Ask at the checkpoint, or record it under Decisions |
| Keeping "before" and "after" tables | Current state only, history lives in git |
