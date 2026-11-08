import CRDTKit

@main
struct CRDTFuzzCommand {
    static func main() {
        print(
            "crdt-fuzz is ready; deterministic scenarios arrive in M1 "
                + "(snapshot format \(CRDTKitMetadata.snapshotFormatVersion))."
        )
    }
}

