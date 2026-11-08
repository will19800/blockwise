# Blockwise delivery roadmap

This roadmap turns the design milestones into small, green commits. Commit subjects are
proposed rather than mandatory; each item should include its tests and documentation.

## M0 - Scaffold

Exit criteria: CI passes an empty test in each Swift package, the app test target, and
the Go module; Swift builds in version 6 mode with complete strict concurrency and zero
warnings.

1. `chore: add repository documentation and engineering rules`
   - Add the design, decisions, interview notes, performance, and metrics documents.
   - Add `.gitignore`, formatting conventions, and contribution guidance.
2. `build: scaffold CRDTKit package and fuzz CLI`
   - Create the Foundation-only library, `crdt-fuzz` executable, and empty XCTest.
3. `build: scaffold SyncKit package`
   - Depend only on `CRDTKit`; add an empty XCTest.
4. `build: scaffold Blockwise iOS app`
   - Create the iOS 18 Xcode project, app/test/UI-test targets, and local package links.
5. `build: scaffold Go relay module and containers`
   - Add the relay command, internal package placeholders, Dockerfile, and Compose file.
6. `ci: verify Swift packages app and relay`
   - Run `swift test`, `xcodebuild test`, and `go test ./...` on GitHub Actions.

## M1 - Text CRDT

Exit criteria: three replicas converge across 1,000 seeded iterations with duplicate
and out-of-order delivery.

1. `test: specify identifiers and Lamport clock behavior`
2. `feat(crdt): implement OpID ReplicaID and Lamport clock`
3. `test: specify RGA insertion deletion and idempotence`
4. `feat(crdt): implement scalar-based RGA text sequence`
5. `feat(crdt): buffer operations with missing dependencies`
6. `feat(fuzz): add deterministic RNG and replayable text actions`
7. `test(fuzz): prove three-replica text convergence`
8. `docs: record RGA tradeoffs and M1 decisions`

## M2 - Block tree and snapshots

Exit criteria: fuzzing covers every non-move operation and snapshot round-trips produce
byte-identical canonical state.

1. `test: specify fractional index ordering and edge cases`
2. `feat(crdt): implement base-62 fractional indexes`
3. `test: specify block lifecycle and delete-wins visibility`
4. `feat(crdt): add blocks LWW properties and create/delete operations`
5. `feat(crdt): flatten visible document state into rows`
6. `test: specify canonical encoding and snapshot compatibility`
7. `feat(crdt): add versioned canonical codec and snapshots`
8. `feat(fuzz): generate all non-move document operations`
9. `docs: record indexing snapshot and deletion tradeoffs`

## M3 - Concurrent moves

Exit criteria: the A-under-B/B-under-A regression trace passes; 10,000 move-inclusive
fuzz iterations converge with every invariant holding.

1. `test: add replicated-tree move regression traces`
2. `feat(crdt): record move history and reversible prior placement`
3. `feat(crdt): integrate moves with undo apply redo ordering`
4. `feat(crdt): prevent deterministic tree cycles`
5. `feat(fuzz): add moves invariant checks and intent validation`
6. `test(fuzz): run ten-thousand-iteration convergence suite`
7. `docs: explain replicated moves and known limitations`

## M4 - Local editor and persistence

Exit criteria: offline edits survive force-quit and relaunch unchanged; a manual
10,000-character typing check remains smooth.

1. `feat(core): add DocumentActor intents changes and isolation tests`
2. `feat(sync): define OpStore and batching contracts`
3. `feat(store): add SwiftData records indexes and model actor`
4. `feat(store): persist pending ops acknowledgements and snapshots`
5. `test(store): verify replay snapshot and crash recovery`
6. `feat(app): add document list and dependency wiring`
7. `feat(editor): render flattened blocks with collection view cells`
8. `feat(editor): bridge TextKit edits to Unicode-scalar operations`
9. `feat(editor): implement split merge indent outdent and block kinds`
10. `feat(editor): preserve selections IME input and remote deltas`
11. `test(ui): cover core offline editing and accessibility identifiers`
12. `docs: record persistence and actor-boundary tradeoffs`

## M5 - Relay and synchronization

Exit criteria: two simulators converge after independent offline editing and reconnect;
the real-relay bot test passes in CI.

1. `feat(server): create documents and authenticate share secrets`
2. `feat(server): sequence deduplicate persist and catch up operations`
3. `test(server): cover concurrency duplicates slow clients and restart`
4. `feat(sync): add protocol messages and transport abstraction`
5. `feat(sync): add deterministic in-memory transport and manual clock`
6. `feat(sync): implement outbox echo acknowledgements and catch-up`
7. `feat(sync): implement reconnect jitter heartbeat and path handling`
8. `feat(sync): add URLSession WebSocket transport`
9. `feat(app): add sharing connection status and offline debug controls`
10. `test(sync): cover resend duplication backoff and cursor recovery`
11. `test(e2e): drive bot replicas against the Docker relay`
12. `ci: run relay-backed convergence tests`

## M6 - Performance and portfolio polish

Exit criteria: every target is measured and recorded, whether met or not; the README
contains a short demo and an honest limitations section.

1. `perf: add signposts fixtures and repeatable benchmark commands`
2. `docs(perf): record baseline measurements and environment`
3. `perf(crdt): coalesce text into run-length spans`
4. `perf(crdt): add indexed visible-offset lookup`
5. `perf(core): update flattened rows incrementally`
6. `perf(store): move snapshot encoding and batching off the main actor`
7. `build: generate metrics documentation from measured outputs`
8. `docs: publish measured results limitations and demo`
9. `test: run the complete release acceptance suite`

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

