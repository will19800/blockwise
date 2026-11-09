import CRDTKit

/// Stable metadata used to verify SyncKit's package boundary.
///
/// Networking and persistence contracts will be introduced in later milestones. Until
/// then, this immutable value confirms that SyncKit can consume CRDTKit without adding
/// another dependency.
public enum SyncKitMetadata: Sendable {
    /// The human-readable package name.
    public static let packageName = "SyncKit"

    /// The CRDT snapshot version this build understands.
    public static let supportedSnapshotFormatVersion =
        CRDTKitMetadata.snapshotFormatVersion
}

