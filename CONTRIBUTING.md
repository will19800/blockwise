# Contributing to Blockwise

Blockwise is built as an explainable portfolio project. Optimize for correctness,
clarity, and reproducibility before cleverness.

## Development order

Follow [`docs/ROADMAP.md`](docs/ROADMAP.md) in order. Do not begin a milestone until the
previous milestone's exit criteria pass. Within a milestone, keep commits small enough
to review and explain independently.

## Before writing code

1. Read [`docs/DESIGN.md`](docs/DESIGN.md) and the relevant roadmap item.
2. Check [`docs/DECISIONS.md`](docs/DECISIONS.md) for settled choices.
3. For CRDT behavior, write the deterministic test or regression trace first.
4. If the design is silent, choose the simplest option and record the reason in the
   decision log. Do not stall implementation for a reversible choice.

## Engineering rules

- Compile Swift in version 6 mode with complete strict concurrency and zero warnings.
- Keep `CRDTKit` limited to the Swift standard library and Foundation.
- Keep `SyncKit` dependent only on `CRDTKit`.
- Do not import UIKit, SwiftUI, SwiftData, or networking APIs into either package unless
  the design explicitly assigns them there.
- Use actors, structured concurrency, `async`/`await`, and `AsyncStream` for new
  concurrency code. Do not add Combine, GCD, locks, `@unchecked Sendable`, or
  `nonisolated(unsafe)` without a documented exception.
- Inject clocks, replica IDs, and random number generators into deterministic code.
- Keep the Go server payload-opaque: it sequences, stores, and broadcasts operations but
  never interprets CRDT content.
- Add no third-party app or CRDT dependencies. The Go WebSocket and SQLite dependencies
  specified in the design are the server-side exceptions.
- Never ignore or skip a failing test. Fix it or document a known issue with a concrete
  follow-up.

## Tests and measurements

Run the smallest relevant test while iterating, then the milestone's complete suite
before declaring its exit criteria complete. Randomized tests must use a printed seed
and produce a replayable trace on failure.

Performance targets are hypotheses until measured. Record the hardware or simulator,
build configuration, fixture size, command, and result in `docs/PERF.md`. Generate
project claims through `Scripts/metrics.sh`; do not type unmeasured numbers into the
README or resume material.

## Commit standard

Use an imperative Conventional Commit subject, optionally with a narrow scope:

```text
feat(crdt): integrate pending inserts when their origin arrives
test(sync): cover duplicate echo after reconnect
docs: explain fractional-index ordering tradeoffs
```

Each commit must:

1. represent one coherent change;
2. include the tests and documentation needed to explain it;
3. pass `git diff --check` and all affected tests;
4. leave `main` buildable and green; and
5. avoid generated files, secrets, local databases, and benchmark output unless the
   repository intentionally tracks them.

## Documentation ownership

- `docs/DESIGN.md`: architecture and behavioral contract
- `docs/ROADMAP.md`: implementation order and exit criteria
- `docs/DECISIONS.md`: choices, deviations, and exceptions with reasons
- `docs/INTERVIEW_NOTES.md`: tradeoffs in plain language
- `docs/PERF.md`: profiling evidence and before/after measurements
- `docs/METRICS.md`: generated, reproducible project metrics

