import CRDTKit
import SwiftUI
import SyncKit

enum BlockwiseMetadata {
    static let enginePackageName = CRDTKitMetadata.packageName
    static let syncPackageName = SyncKitMetadata.packageName
    static let snapshotFormatVersion = SyncKitMetadata.supportedSnapshotFormatVersion
}

@main
struct BlockwiseApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 8) {
                Text("Blockwise")
                    .font(.largeTitle)
                    .accessibilityIdentifier("blockwise.title")

                Text("Offline-first editor scaffold")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

