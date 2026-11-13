# Decisions

Record choices not settled by the design document and every intentional deviation.

| Date | Decision | Reason | Status |
| --- | --- | --- | --- |
| 2026-11-07 | Use `blockwise` as the repository name. | It is the working title and repository name in the design. | Accepted |
| 2026-11-07 | Create the GitHub repository as private initially. | Safest default while the portfolio project is being built; visibility can change later. | Accepted |
| 2026-11-08 | Use `com.willchen.Blockwise` as the app bundle identifier. | It is stable, conventional, and can be changed before distribution without affecting the scaffold. | Accepted |
| 2026-11-09 | Use `github.com/will19800/blockwise/Server` as the Go module path. | It matches the repository and the design's `Server/` monorepo directory exactly. | Accepted |
| 2026-11-09 | Listen on port 8080 by default with an environment override. | It is conventional for a containerized HTTP service and keeps local and Compose setup simple. | Accepted |
| 2026-11-10 | Consolidate the remaining roadmap into 30 cohesive commits. | Larger vertical slices reduce delivery overhead while preserving every milestone exit criterion and test gate. | Accepted |
| 2026-11-13 | Represent each text atom as one Unicode scalar and use its insertion operation ID as its stable identity. | Scalars have a deterministic, platform-independent encoding and let selection and deletion refer to immutable CRDT identities; user-perceived grapheme handling remains an editor-layer responsibility. | Accepted |
| 2026-11-13 | Keep the first RGA implementation as readable linear storage with permanent tombstones. | Linear scans make integration and invariants easy to audit during correctness work. Indexed lookup, spans, and garbage collection should be driven by M6 measurements and causal-stability support rather than premature complexity. | Accepted |
| 2026-11-13 | Buffer missing text dependencies by atom ID and suppress duplicates by operation ID. | Inserts can precede their origin and deletes can precede their target. A dependency-keyed buffer releases work immediately when the atom arrives, while applied and pending ID sets make redelivery idempotent. | Accepted |
| 2026-11-13 | Use SplitMix64 and derive an independent seed for each convergence-fuzz iteration. | The generator is tiny, deterministic across platforms, and makes a failing iteration directly replayable without depending on process-global randomness. | Accepted |

