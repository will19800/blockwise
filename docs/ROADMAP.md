# Blockwise delivery roadmap

This roadmap turns the design milestones into cohesive, green commits. Commit subjects
are proposed rather than mandatory; each item includes its tests and documentation.
The remaining plan was consolidated to 30 commits after the initial scaffolds were
complete, reducing ceremony without weakening milestone exit criteria.

## M0 - Scaffold

Exit criteria: CI passes an empty test in each Swift package, the app test target, and
the Go module; Swift builds in version 6 mode with complete strict concurrency and zero
warnings.

Completed: repository documentation, both Swift packages, the iOS app and test targets,
and the Go relay/container scaffold.

1. `ci: verify Swift packages app and relay`
   - Run `swift test`, `xcodebuild test`, and `go test ./...` on GitHub Actions.

## M1 - Text CRDT

Exit criteria: three replicas converge across 1,000 seeded iterations with duplicate
and out-of-order delivery.

Completed locally: immutable text operations, dependency buffering, duplicate
suppression, and deterministic RGA integration are covered by unit tests and the seeded
fuzzer. The M1 exit run completed 1,000 three-replica iterations with delayed,
out-of-order, and duplicate delivery. GitHub-hosted verification remains pending on the
repository-level Actions admission issue recorded under M0.

1. `feat(crdt): add identifiers Lamport clocks and tested RGA primitives`
2. `feat(crdt): integrate pending text operations and idempotent delivery`
3. `feat(fuzz): prove deterministic three-replica text convergence`
4. `docs: record text CRDT tradeoffs decisions and M1 results`

## M2 - Block tree and snapshots

Exit criteria: fuzzing covers every non-move operation and snapshot round-trips produce
byte-identical canonical state.

1. `feat(crdt): add tested base-62 fractional indexes`
2. `feat(crdt): add block lifecycle properties and row flattening`
3. `feat(crdt): add canonical codec and versioned snapshots`
4. `feat(fuzz): verify non-move documents and record M2 tradeoffs`

## M3 - Concurrent moves

Exit criteria: the A-under-B/B-under-A regression trace passes; 10,000 move-inclusive
fuzz iterations converge with every invariant holding.

1. `feat(crdt): implement move log integration with regression traces`
2. `feat(fuzz): verify cycle prevention moves and all invariants`
3. `docs: explain replicated moves limitations and M3 results`

## M4 - Local editor and persistence

Exit criteria: offline edits survive force-quit and relaunch unchanged; a manual
10,000-character typing check remains smooth.

1. `feat(core): add DocumentActor and OpStore contracts with isolation tests`
2. `feat(store): persist batched ops snapshots and crash recovery`
3. `feat(app): add document list dependency wiring and launch restore`
4. `feat(editor): render blocks and bridge TextKit scalar edits`
5. `feat(editor): add split merge indent outdent reorder and block kinds`
6. `feat(editor): preserve selection IME remote deltas and accessibility`
7. `test(app): verify offline recovery UI flows and M4 tradeoffs`

## M5 - Relay and synchronization

Exit criteria: two simulators converge after independent offline editing and reconnect;
the real-relay bot test passes in CI.

1. `feat(server): create authenticate sequence and persist documents`
2. `feat(sync): add protocol transports manual clock and network simulator`
3. `feat(sync): implement outbox acknowledgements resend and catch-up`
4. `feat(sync): add WebSocket reconnect jitter heartbeat and path handling`
5. `feat(app): add sharing status debug controls and sync integration tests`
6. `test(e2e): verify Docker relay convergence in CI and record M5 results`

## M6 - Performance and portfolio polish

Exit criteria: every target is measured and recorded, whether met or not; the README
contains a short demo and an honest limitations section.

1. `perf: add signposts fixtures benchmarks and recorded baselines`
2. `perf(crdt): add run-length spans and indexed visible offsets`
3. `perf(core): optimize row updates snapshot encoding and persistence`
4. `build: generate reproducible metrics and performance documentation`
5. `docs: publish measured results demo limitations and acceptance results`

## Stretch work

Only after M6: local inverse-operation undo/redo, remote cursors anchored to RGA IDs,
then tombstone and move-log garbage collection past a causally stable frontier.

## Commit gate

Before every commit:

1. Run all tests affected by the change.
2. Run the milestone's full suite before declaring its exit criteria complete.
3. Record ambiguous choices in `docs/DECISIONS.md`.
4. Update `docs/INTERVIEW_NOTES.md` for meaningful design tradeoffs.
5. Never add an unmeasured number to the README or resume material.

