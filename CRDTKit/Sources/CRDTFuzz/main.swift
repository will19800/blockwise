import CRDTFuzzSupport
import Foundation

@main
struct CRDTFuzzCommand {
    static func main() throws {
        var configuration = TextFuzzConfiguration()
        let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())

        if arguments.contains("--help") || arguments.contains("-h") {
            print(usage)
            return
        }

        var index = 0
        while index < arguments.count {
            let option = arguments[index]
            guard index + 1 < arguments.count else {
                throw ArgumentError("missing value for \(option)")
            }
            let value = arguments[index + 1]

            switch option {
            case "--iterations":
                configuration.iterations = try parseInt(value, option: option)
            case "--actions":
                configuration.actionsPerIteration = try parseInt(value, option: option)
            case "--replicas":
                configuration.replicaCount = try parseInt(value, option: option)
            case "--seed":
                configuration.seed = try parseSeed(value)
            default:
                throw ArgumentError("unknown option \(option)\n\n\(usage)")
            }
            index += 2
        }

        let summary = try TextConvergenceFuzzer.run(configuration: configuration)
        print(
            "Passed \(summary.iterations) iterations with "
                + "\(summary.generatedOperations) operations and "
                + "\(summary.deliveries) deliveries "
                + "(seed 0x\(String(summary.seed, radix: 16)))."
        )
    }

    private static func parseInt(_ value: String, option: String) throws -> Int {
        guard let parsed = Int(value) else {
            throw ArgumentError("invalid integer for \(option): \(value)")
        }
        return parsed
    }

    private static func parseSeed(_ value: String) throws -> UInt64 {
        let radix: Int
        let digits: Substring
        if value.lowercased().hasPrefix("0x") {
            radix = 16
            digits = value.dropFirst(2)
        } else {
            radix = 10
            digits = Substring(value)
        }
        guard let parsed = UInt64(digits, radix: radix) else {
            throw ArgumentError("invalid seed: \(value)")
        }
        return parsed
    }

    private static let usage = """
        Usage: crdt-fuzz [options]

          --iterations N  Independent seeded scenarios (default: 1000)
          --actions N     Random actions per scenario (default: 100)
          --replicas N    Replica count from 2 through 5 (default: 3)
          --seed N        Decimal or 0x-prefixed base seed (default: 0xB10C715E)
          --help          Show this help
        """

    private struct ArgumentError: Error, CustomStringConvertible {
        let description: String

        init(_ description: String) {
            self.description = description
        }
    }
}

