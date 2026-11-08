# Blockwise

Blockwise is a native iOS block editor that works fully offline and converges across
devices through a deterministic CRDT sync engine written in Swift.

The project is intentionally built as an explainable portfolio piece: the CRDT is
implemented without third-party libraries, the relay server does not interpret
operations, and every performance claim must be backed by a recorded measurement.

## Scope

- Swift 6 with complete strict concurrency
- iOS 18+, SwiftUI app shell, and a UIKit/TextKit 2 editor
- Pure Swift `CRDTKit` and `SyncKit` packages
- Go relay server with WebSockets and SQLite
- Offline-first operation log and snapshots
- Seeded convergence fuzzing and reproducible regression traces

Accounts, permissions, inline formatting, images, tables, databases, end-to-end
encryption, iPad, macOS, and App Store distribution are outside the v1 scope.

## Working agreement

Development follows [the milestone roadmap](docs/ROADMAP.md). Each commit should be
small, independently reviewable, and leave `main` green. Implementation does not move
to the next milestone until the current milestone's exit criteria pass.

Open choices and deviations belong in `docs/DECISIONS.md`. Interview-facing tradeoffs
belong in `docs/INTERVIEW_NOTES.md`. Only measured values may appear in project claims.

## Status

Planning complete. M0 (repository scaffold) is next.

