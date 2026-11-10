/// An element in a replicated growable array.
public struct RGAElement: Codable, Equatable, Sendable {
    public let id: OpID
    public let scalar: UInt32
    public let origin: OpID?
    public internal(set) var deleted: Bool

    public init(id: OpID, scalar: UInt32, origin: OpID?, deleted: Bool = false) {
        self.id = id
        self.scalar = scalar
        self.origin = origin
        self.deleted = deleted
    }
}

/// Failures that require an operation to be rejected or deferred.
public enum RGAError: Error, Equatable, Sendable {
    case conflictingElementID(OpID)
    case invalidUnicodeScalar(UInt32)
    case missingOrigin(OpID)
    case missingTarget(OpID)
    case nonCausalOrigin(origin: OpID, child: OpID)
}

/// A linear reference implementation of replicated growable array text.
///
/// This version intentionally favors readable integration logic over indexed lookup.
/// M6 replaces the linear storage after measurements identify the useful structure.
public struct RGA: Codable, Equatable, Sendable {
    private var storage: [RGAElement]

    public init() {
        storage = []
    }

    /// All elements in deterministic traversal order, including tombstones.
    public var elements: [RGAElement] {
        storage
    }

    /// The IDs of visible elements in traversal order.
    public var visibleElementIDs: [OpID] {
        storage.compactMap { element in
            element.deleted ? nil : element.id
        }
    }

    /// The visible Unicode scalars in traversal order.
    public var visibleScalars: [UInt32] {
        storage.compactMap { element in
            element.deleted ? nil : element.scalar
        }
    }

    /// The user-visible text represented by the non-deleted elements.
    public var text: String {
        String(decoding: visibleScalars, as: UTF32.self)
    }

    /// Integrates one scalar insertion.
    ///
    /// Returns `false` when the exact element was already integrated. A reused ID with
    /// different content is rejected because operation IDs are globally unique.
    @discardableResult
    public mutating func insert(id: OpID, origin: OpID?, scalar: UInt32) throws -> Bool {
        guard Unicode.Scalar(scalar) != nil else {
            throw RGAError.invalidUnicodeScalar(scalar)
        }

        if let existing = storage.first(where: { $0.id == id }) {
            guard existing.scalar == scalar, existing.origin == origin else {
                throw RGAError.conflictingElementID(id)
            }

            return false
        }

        let anchorIndex: Int
        if let origin {
            guard origin < id else {
                throw RGAError.nonCausalOrigin(origin: origin, child: id)
            }
            guard let index = storage.firstIndex(where: { $0.id == origin }) else {
                throw RGAError.missingOrigin(origin)
            }
            anchorIndex = index
        } else {
            anchorIndex = -1
        }

        var insertionIndex = anchorIndex + 1
        while insertionIndex < storage.count, storage[insertionIndex].id > id {
            insertionIndex += 1
        }

        storage.insert(
            RGAElement(id: id, scalar: scalar, origin: origin),
            at: insertionIndex
        )
        return true
    }

    /// Marks an element as a tombstone while retaining its position and identity.
    ///
    /// Returns `false` when the element was already deleted.
    @discardableResult
    public mutating func delete(target: OpID) throws -> Bool {
        guard let index = storage.firstIndex(where: { $0.id == target }) else {
            throw RGAError.missingTarget(target)
        }
        guard !storage[index].deleted else {
            return false
        }

        storage[index].deleted = true
        return true
    }
}

