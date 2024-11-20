import Foundation
import ArgumentParser


@main
struct RGVerify: ParsableCommand {
    @Argument var inputFile: String

    mutating func run() throws {
        let expandedInput = (inputFile as NSString).expandingTildeInPath
        print("Verifying '\(inputFile)'...")
        let garden = try RGParser.parse(filePath: expandedInput)
        print("Parsed '\(inputFile)'...")
        var puzzle = [[String]]()
        for r in garden.rows {
            var row = [String]()
            for e in r {
                let answer = e.answer
                let letters = answer.asArray
                row.append(contentsOf: letters)
            }
            puzzle.append(row)
        }

        print("Verifying light blooms...")
        let lights = [[1,0], [1,6], [1,12], [4,3], [4, 9]]
        for (i, l) in lights.enumerated() {
            let bloom = bloom(for: l, in: puzzle)
            let _ = try verifyBloom(answer: garden.light[i].answer, bloom: bloom)
            print("Verified \(bloom.joined()) in \(garden.light[i].answer)")
        }
        print("Verifying medium blooms...")
        let mediums = [[0,0], [0,3], [3,0], [3,6], [3, 12], [6,3], [6,9]]
        for (i, m) in mediums.enumerated() {
            let bloom = bloom(for: m, in: puzzle)
            let _ = try verifyBloom(answer: garden.medium[i].answer, bloom: bloom)
            print("Verified \(bloom.joined()) in \(garden.medium[i].answer)")
        }
        print("Verifying dark blooms...")
        let darks = [[2,3], [2,9], [5,0], [5,6], [5, 12]]
        for (i, d) in darks.enumerated() {
            let bloom = bloom(for: d, in: puzzle)
            let _ = try verifyBloom(answer: garden.dark[i].answer, bloom: bloom)
            print("Verified \(bloom.joined()) in \(garden.dark[i].answer)")
        }
    }

    func bloom(for coord: [Int], in puzzle: [[String]]) -> [String] {
        var result = [String]()
        let y = coord[0]
        let x = coord[1]
        //special case top rows
        if y == 0 && x == 0 {
            result.append(puzzle[y][x])
            result.append(puzzle[y][x + 1])
            result.append(puzzle[y][x + 2])
            result.append(puzzle[y + 1][x + 5])
            result.append(puzzle[y + 1][x + 4])
            result.append(puzzle[y + 1][x + 3])
            return result
        }
        if y == 0 && x == 3 {
            result.append(puzzle[y][x])
            result.append(puzzle[y][x + 1])
            result.append(puzzle[y][x + 2])
            result.append(puzzle[y + 1][x + 8])
            result.append(puzzle[y + 1][x + 7])
            result.append(puzzle[y + 1][x + 6])
            return result
        }
        // special case bottom rows
        if y == 6 && x == 3 {
            result.append(puzzle[y][x])
            result.append(puzzle[y][x + 1])
            result.append(puzzle[y][x + 2])
            result.append(puzzle[y + 1][x - 1])
            result.append(puzzle[y + 1][x - 2])
            result.append(puzzle[y + 1][x - 3])
            return result
        }
        if y == 6 && x == 9 {
            result.append(puzzle[y][x])
            result.append(puzzle[y][x + 1])
            result.append(puzzle[y][x + 2])
            result.append(puzzle[y + 1][x - 4])
            result.append(puzzle[y + 1][x - 5])
            result.append(puzzle[y + 1][x - 6])
            return result
        }
        result.append(puzzle[y][x])
        result.append(puzzle[y][x + 1])
        result.append(puzzle[y][x + 2])
        result.append(puzzle[y + 1][x + 2])
        result.append(puzzle[y + 1][x + 1])
        result.append(puzzle[y + 1][x + 0])
        return result
    }

    func verifyBloom(answer: String, bloom: [String]) throws -> Bool {
        print("Verifying \(bloom.joined())")
        let bloomAnswer = answer.asArray
        guard bloom.count == 6 else {
            throw RuntimeError("Failed parsing: row answer segment is not 6 letters.")
        }
        guard bloomAnswer.count >= 6 else {
            throw RuntimeError("Failed parsing: bloom answer is not 6 or more letters.")
        }
        let indexes = bloom.indexes { $0 == bloomAnswer[0] }
        //print(indexes)
        for index in indexes {
            var next = index
            // try clockwise first
            var matchCount = 0
            for j in 0..<6 {
                if bloomAnswer[j] == bloom[next] {
                    //print("match: \(bloomAnswer[next]), \(bloom[j])")
                    matchCount += 1
                } else {
                    //print("no match: \(bloomAnswer[next]), \(bloom[j])")
                    break
                }
                next = next < 5 ? next + 1 : 0
            }
            if matchCount == 6 {
                print("Bloom is clockwise")
                let newBloom = reorder(bloom, from: index, clockwise: true)
                //print(newBloom)
                if newBloom == bloomAnswer {
                    return true
                }
            } else {
                print("Bloom is counter-clockwise")
                let newBloom = reorder(bloom, from: index, clockwise: false)
                //print(newBloom)
                if newBloom == bloomAnswer {
                    return true
                }
            }
        }
        throw RuntimeError("Could not verify bloom \(answer). Received fill \(bloom.joined())")
    }

    func reorder(_ array: [String], from i: Int, clockwise: Bool) -> [String] {
        var newArray = [String]()
        var next = i
        for _ in 0..<6 {
            newArray.append(array[next])
            if clockwise {
                next = next < 5 ? next + 1 : 0
            } else {
                next = next > 0 ? next - 1 : 5
            }
        }
        return newArray
    }
}

extension String {
    var asArray: [String] {
        return self.compactMap { c in
            if c.isLetter {
                return String(c)
            }
            return nil
        }
    }
}

extension Array where Element: Equatable {
    func indexes(predicate: (Element) -> Bool) -> [Int] {
        var result: [Int] = []
        for (index, element) in enumerated() {
            if predicate(element) {
                result.append(index)
            }
        }
        return result
    }
}

struct RuntimeError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) {
        self.description = description
    }
}
