# Interview notes

## M1: text CRDT

### Why an RGA

The text model is a replicated growable array rather than an operational-transform
pipeline or a position-only sequence. Every inserted scalar receives a permanent ID,
and later edits name IDs instead of offsets. That makes operations immutable and lets
replicas integrate the same operation set without relying on relay order or a central
revision number.

The tradeoff is storage and lookup cost. Deletion leaves a tombstone so descendants can
continue to reference the deleted atom, and the first implementation scans a linear
array. This is deliberately easy to inspect and test. M6 will measure whether run-length
spans and indexed visible offsets are justified; tombstone collection requires a
causally stable frontier and remains stretch work.

### Deterministic concurrent insertion

An insertion names its origin atom, or the root, and uses its Lamport/replica operation
ID as the new atom ID. Concurrent children of the same origin sort by that total ID.
Because every replica uses the same immutable IDs and comparison, arrival order cannot
change the final traversal. A Lamport counter captures causal progress; the replica ID
breaks ties without coordination.

### Unicode and editor boundaries

CRDT atoms are Unicode scalars, not UTF-16 code units or user-perceived characters.
Scalars have a stable encoding and map cleanly to Swift strings, while avoiding invalid
surrogate fragments. A visible emoji can still contain several scalars, so grapheme-safe
cursor movement and deletion belong in the TextKit bridge: it converts an editor range
into the corresponding scalar IDs before issuing operations.

### Late and duplicate delivery

An insert may arrive before its origin, and a delete may arrive before its target. The
engine retains these operations in a dependency-keyed buffer and retries them when the
missing insertion integrates. Applied and pending operation-ID sets make both network
echoes and repeated replay idempotent. Application is transactional, so a malformed
operation cannot leave partially released buffered work behind.

### Correctness evidence

The seeded fuzzer creates local edits on three replicas, injects delay, reordering, and
duplicates, then replays the complete immutable history in a different order at every
replica. It verifies equal internal state and visible text, an empty dependency buffer,
the complete applied-operation set, and exactly one materialized atom for every insert.

The M1 exit run used seed `0xB10C715E` for 1,000 iterations of 100 actions. It generated
71,111 operations and performed 285,663 deliveries with no divergence. The command
prints the exact iteration seed and trace on failure, so a random failure becomes a
permanent regression case instead of an unrepeatable event.

## Later milestones

Future notes will cover the replicated move log and cycle prevention, fractional sibling
positions, actor ownership and reentrancy boundaries, and SwiftData behind the `OpStore`
abstraction as those pieces are implemented.

