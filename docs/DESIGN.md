# Blockwise design

## Overview

Blockwise is a native iOS block editor that works fully offline and converges across
devices through an operation-based CRDT written in Swift. It is a portfolio project for
iOS roles, so every subsystem and tradeoff must be explainable in an interview.

### Goals

- Edit without a network and synchronize automatically after reconnecting.
- Model documents as nested paragraph, heading, to-do, bullet, and toggle blocks.
- Preserve typed text and converge to identical state after concurrent edits.
- Keep the sync engine deterministic, pure Swift, and fuzz-tested.
- Keep typing responsive on large documents.
- Support every published metric with a reproducible measurement.

Accounts, permissions, inline formatting, media, tables, databases, end-to-end
encryption, non-iPhone platforms, and App Store distribution are outside v1.

## Technology and boundaries

- Swift 6 with complete strict concurrency; iOS 18 minimum.
- SwiftUI and Observation for the app shell.
- UIKit collection view cells with TextKit 2 text views for the editor.
- SwiftData behind an `OpStore` protocol for persistence.
- Actors, structured concurrency, `AsyncStream`, and injected clocks.
- Local Swift packages named `CRDTKit` and `SyncKit`.
- A Go 1.22+ relay using WebSockets, SQLite, and Docker Compose.
- XCTest, Go tests, seeded fuzzing, and GitHub Actions.

`CRDTKit` imports only the Swift standard library and Foundation and must build with
`swift test` on macOS. `SyncKit` depends only on `CRDTKit`. The server sequences, stores,
and broadcasts opaque operation bytes; it contains no CRDT behavior.

## Document model

A document is a tree of blocks under a reserved root. An immutable operation has an ID
containing a Lamport counter and replica ID, ordered by counter and then replica. A
block's ID is the creation operation's ID; a text atom's ID is its insertion operation's
ID.

Block properties use last-writer-wins registers. Text is an RGA of Unicode scalars with
tombstones. Siblings sort by a base-62 fractional position and then block ID. Block
deletion hides its current subtree but does not individually tombstone descendants, so
a concurrent move can preserve a descendant moved outside the deleted parent.

The operation set covers block creation, movement, kind and checked-state changes,
block deletion, scalar insertion, and scalar deletion. Applying an operation twice has
the same effect as applying it once. Missing dependencies are buffered until they
arrive.

Required invariants:

1. Every non-root block has exactly one parent.
2. The tree contains no cycles on any replica at any time.
3. A set of operations always produces a byte-identical canonical state encoding.
4. Applying an operation is idempotent.

## CRDT integration

Each replica advances a Lamport clock for local operations and observes remote counters.
RGA insertions are ordered deterministically among concurrent children of the same
origin; deletions mark atoms as tombstones. Property operations accept only a writer ID
newer than the stored writer.

Block movement follows the replicated move-log approach: insert a move into total ID
order, undo newer moves, apply the inserted move, and redo the newer moves. A move into
itself or a descendant is logged but skipped, ensuring every replica rejects the same
cycle-producing operation.

Correctness never depends on relay order. Tests deliver operations out of order, more
than once, and after arbitrary delays. Snapshots canonically encode all state required
to resume integration, including tombstones, registers, the move log, clock, and applied
operation set.

Known v1 limitations are unbounded tombstones and move logs, fractional-position
interleaving under concurrent insertion, and imperfect semantics when splitting a block
concurrently with edits to its tail.

## Persistence and synchronization

The app writes an append-only operation log and periodic snapshots. Local edits apply in
memory, persist as pending, and only then become eligible to send. Writes batch for up
to 100 milliseconds or 50 operations and flush on backgrounding. Snapshots occur every
500 operations and on backgrounding. Launch restores a snapshot, replays later local
operations, and resumes relay catch-up from the last server sequence.

One WebSocket connects per document. The client sends its protocol version, replica ID,
and last server sequence. The relay returns later operations, then live operations. It
echoes accepted operations to the sender; that echo is the acknowledgement. Reconnects
resend unacknowledged operations, which the server deduplicates by operation ID.

Connection state covers idle, connecting, handshaking, live, and jittered backoff.
Network-path changes, heartbeats, foreground transitions, and a simulated-offline debug
control drive reconnection. `SyncTransport` isolates the engine from URLSession and
enables deterministic loss, duplication, reordering, and latency in tests.

## UI and concurrency

One `DocumentActor` owns each open document's CRDT state and flattened rows. One
`SyncEngine` actor owns its connection, outbox, and backoff. A SwiftData model actor owns
database access. View models and editor controllers remain on the main actor.

Only `Sendable` values cross actor boundaries. State mutations contain no suspension
between their read and write phases. Document changes are not dropped; status streams
may retain only the newest value. The main actor batches UI application once per run-loop
turn and performs no heavy CRDT, flattening, or snapshot work.

The editor supports block split and merge, indent and outdent, drag reorder, slash-menu
kind changes, checkboxes, Dynamic Type, VoiceOver, stable selection anchors, and queued
remote deltas during marked-text composition.

## Verification and performance

Unit tests cover clocks, RGA, registers, fractional indexing, move integration, and
snapshot encoding. Permanent regression traces cover concurrent insertion and deletion,
opposite tree moves, moves into deleted parents, and dependencies arriving late.

The convergence fuzzer uses two to five replicas, seeded random actions, duplicate and
out-of-order delivery, replayable failure traces, canonical-state equality, structural
invariants, and an intent check that preserves every non-deleted insertion exactly once.
Persistence, sync, Go relay, Docker-backed end-to-end, and a small stable UI suite form
the remaining test layers.

Profiling records baselines before optimization. Initial areas of interest are RGA
offset lookup, row flattening, per-character allocation, snapshot isolation, and wire
encoding. Results record device or simulator, fixture, build mode, and method. Only
measured values may become project claims.

## Delivery

Implementation follows `docs/ROADMAP.md` from M0 through M6. Stretch work begins only
after M6: inverse-operation undo/redo, remote cursors anchored to RGA IDs, then garbage
collection after a causally stable frontier.

