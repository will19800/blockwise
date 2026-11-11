import CRDTFuzzSupport
import XCTest

final class TextConvergenceFuzzerTests: XCTestCase {
    func testOneThousandThreeReplicaScenariosConverge() throws {
        let summary = try TextConvergenceFuzzer.run(
            configuration: TextFuzzConfiguration(
                iterations: 1_000,
                actionsPerIteration: 50,
                replicaCount: 3,
                seed: 0xB10C_715E
            )
        )

        XCTAssertEqual(summary.iterations, 1_000)
        XCTAssertGreaterThan(summary.generatedOperations, 0)
        XCTAssertGreaterThan(summary.deliveries, summary.generatedOperations)
    }

    func testSameSeedProducesSameSummary() throws {
        let configuration = TextFuzzConfiguration(
            iterations: 10,
            actionsPerIteration: 20,
            replicaCount: 3,
            seed: 42
        )

        XCTAssertEqual(
            try TextConvergenceFuzzer.run(configuration: configuration),
            try TextConvergenceFuzzer.run(configuration: configuration)
        )
    }

    func testRejectsUnsupportedReplicaCount() {
        XCTAssertThrowsError(
            try TextConvergenceFuzzer.run(
                configuration: TextFuzzConfiguration(replicaCount: 1)
            )
        ) { error in
            XCTAssertEqual(
                error as? TextFuzzError,
                .invalidConfiguration("replicas must be between 2 and 5")
            )
        }
    }

    func testSplitMix64KnownSequence() {
        var generator = SplitMix64(seed: 0)

        XCTAssertEqual(generator.next(), 0xE220_A839_7B1D_CDAF)
        XCTAssertEqual(generator.next(), 0x6E78_9E6A_A1B9_65F4)
        XCTAssertEqual(generator.next(), 0x06C4_5D18_8009_454F)
    }
}
