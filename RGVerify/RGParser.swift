import Foundation
import Yams
import ZIPFoundation

class RGParser {
    static func parse(filePath: String) throws -> RowsGarden {
        var path = URL(fileURLWithPath: filePath)
        if (filePath as NSString).pathExtension == "rgz" {
            let fromURL = URL(fileURLWithPath: filePath)
            let toURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)")
            try FileManager.default.unzipItem(at: fromURL, to: toURL)
            let unzipped = try FileManager.default.contentsOfDirectory(at: toURL, includingPropertiesForKeys: nil)
            guard let file = unzipped.first else {
                throw RuntimeError("Could not unzip file")
            }
            path = file
        }
        let yamlString = try String(contentsOf: path, encoding: .utf8)
        let yamlStringArray = yamlString.components(separatedBy: "\n")
        let correctedYAMLStringArray = yamlStringArray.map { line in
            var fixedLine = line.trimmingCharacters(in: .newlines)
            if let colonMatch = fixedLine.firstMatch(of: /^( *[^:]+:)([^ ]..+)$/) {
                fixedLine = "\(colonMatch.1) \(colonMatch.2)"
            }
            if let escapeMatch = fixedLine.firstMatch(of: /^( *[^:]+: +)((?![>|]).+)$/) {
                var value = escapeMatch.2
                value = value.replacing(/"/, with: "\\\"")
                value = "\"\(value)\""
                fixedLine = "\(escapeMatch.1)\(value)"
            }
            return fixedLine
        }
        let correctedYAML = correctedYAMLStringArray.joined(separator: "\n")
        let decoder = YAMLDecoder()
        return try decoder.decode(RowsGarden.self, from: correctedYAML)
    }
}
