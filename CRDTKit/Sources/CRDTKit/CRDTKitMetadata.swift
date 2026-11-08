/// Stable metadata shared by CRDTKit tools and tests.
///
/// This type intentionally contains no mutable process state. Deterministic CRDT state
/// will be introduced behind explicit value types in M1.
public enum CRDTKitMetadata: Sendable {
    /// The current canonical snapshot format.
    public static let snapshotFormatVersion = 1

    /// The human-readable package name used by command-line tools.
    public static let packageName = "CRDTKit"
}

