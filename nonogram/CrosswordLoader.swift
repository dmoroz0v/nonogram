//
//  CrosswordLoader.swift
//  nonogram
//
//  Created by Denis S. Morozov on 22.01.2023.
//

import Foundation

final class CrosswordLoader {
    func load(url: URL, completion: @escaping (_ horizontalLinesHunks: [[Field.LineHunk]],
                                               _ verticalLinesHunks: [[Field.LineHunk]],
                                               _ solution: [[Int]],
                                               _ colors: [Field.Color]) -> Void, failure: @escaping () -> Void) {
        DispatchQueue.global().async {
            do {
                let data = try Data(contentsOf: url)

                var d: [[Int]] = []

                if var s = String(data: data, encoding: .utf8)?.matching("d=\\[\\[.+?\\]\\]").first {
                    s = s.replacingOccurrences(of: "d=[[", with: "")
                    s = s.replacingOccurrences(of: "]]", with: "")
                    let rows = s.components(separatedBy: "],[")

                    for row in rows {
                        var arr: [Int] = []
                        for ch in row.split(separator: ",") {
                            arr.append(Int(ch)!)
                        }
                        d.append(arr)
                    }
                } else {
                    failure()
                    return
                }

                var E: [[Int]] = []

                let D: Int = d[1][0] % d[1][3] + d[1][1] % d[1][3] - d[1][2] % d[1][3]
                let C: Int = d[2][0] % d[2][3] + d[2][1] % d[2][3] - d[2][2] % d[2][3]
                let Aa: Int = d[3][0] % d[3][3] + d[3][1] % d[3][3] - d[3][2] % d[3][3]
                var colors: [String] = []

                for x in 5..<(Aa + 5) {
                    let Ea = d[x][0] - d[4][1]
                    let Fa = d[x][1] - d[4][0]
                    let Ga = d[x][2] - d[4][3]

                    var s1 = String(format:"%02X", Ea + 256)
                    s1 = String(s1[(s1.index(s1.startIndex, offsetBy: 1))..<s1.endIndex])

                    var s2 = String(format:"%02X", ((Fa + 256) << 8) + Ga)
                    s2 = String(s2[(s2.index(s1.startIndex, offsetBy: 1))..<s2.endIndex])

                    colors.append(s1 + s2)
                }

                for w in 0..<C {
                    E.append([])
                    for _ in 0..<D {
                        E[w].append(0)
                    }

                }
                let V = Aa + 5
                let Ha = d[V][0] % d[V][3] * (d[V][0] % d[V][3]) + d[V][1] % d[V][3] * 2 + d[V][2] % d[V][3]
                let Ia: [Int] = d[V + 1]

                for x in (V + 2)..<(V + 1 + Ha) {
                    let start: Int = (d[x][0] - Ia[0] - 1)
                    let end: Int = (d[x][0] - Ia[0] + d[x][1] - Ia[1] - 1)
                    for v in start..<end {
                        E[d[x][3] - Ia[3] - 1][v] = d[x][2] - Ia[2]
                    }
                }

                var verticalLinesHunks: [[Field.LineHunk]] = []
                var horizontalLinesHunks: [[Field.LineHunk]] = []

                func lineHunks(
                    startRef: (row: Int, column: Int),
                    endRef: (row: Int, column: Int),
                    step: (row: Int, column: Int)
                ) -> [Field.LineHunk] {
                    var result: [Field.LineHunk] = []
                    var currentRef = startRef
                    var prevValue: Int = -1
                    var n = 0
                    while currentRef != endRef {
                        let value = E[currentRef.row][currentRef.column]
                        if prevValue != value && n != 0 {
                            let color = colors[prevValue - 1]
                            result.append(.init(color: .init(rgb: color), n: n))
                            n = 0
                        }
                        if value != 0 {
                            n += 1
                        }
                        currentRef.row += step.row
                        currentRef.column += step.column
                        prevValue = value
                    }
                    if n != 0 {
                        let color = colors[prevValue - 1]
                        result.append(.init(color: .init(rgb: color), n: n))
                    }
                    return result
                }

                for rowIndex in 0..<E.count {
                    horizontalLinesHunks.append(lineHunks(
                        startRef: (row: rowIndex, column: 0),
                        endRef: (row: rowIndex, column: E[rowIndex].count),
                        step: (row: 0, column: 1)
                    ))
                }

                for columnIndex in 0..<E[0].count {
                    verticalLinesHunks.append(lineHunks(
                        startRef: (row: 0, column: columnIndex),
                        endRef: (row: E.count, column: columnIndex),
                        step: (row: 1, column: 0)
                    ))
                }

                completion(horizontalLinesHunks, verticalLinesHunks, E, colors.map({
                    Field.Color(rgb: $0)
                }))
            }
            catch {
                failure()
            }
        }
    }
}

private extension String {
    func matching(_ pattern: String, options: NSRegularExpression.Options = []) -> [String] {
        guard let regEx = try? NSRegularExpression(pattern: pattern, options: options) else {
            return []
        }

        return regEx.matches(in: self, range: NSRange(location: 0, length: count)).map { match in
            guard let range = Range(match.range) else {
                return ""
            }
            let startIndex = index(self.startIndex, offsetBy: range.startIndex)
            let endIndex = index(self.startIndex, offsetBy: range.endIndex)
            return String(self[startIndex..<endIndex])
        }
    }
}
