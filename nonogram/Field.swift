//
//  Field.swift
//  nonogram
//
//  Created by Denis S. Morozov on 12.01.2023.
//

import Foundation
import UIKit

struct Field: Codable {
    struct Color: Codable, Equatable {
        var c: UIColor
        var id: String

        init(rgb: String) {
            let scanner = Scanner(string: rgb)
            var hexNumber: UInt64 = 0

            scanner.scanHexInt64(&hexNumber)
            let r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
            let g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
            let b = CGFloat((hexNumber & 0x0000ff) >> 0) / 255

            c = UIColor(red: r, green: g, blue: b, alpha: 1)
            id = rgb
        }

        enum CodingKeys: String, CodingKey {
            case color
        }
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .color)
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .color)
            let scanner = Scanner(string: id)
            var hexNumber: UInt64 = 0

            scanner.scanHexInt64(&hexNumber)
            let r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
            let g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
            let b = CGFloat((hexNumber & 0x0000ff) >> 0) / 255

            c = UIColor(red: r, green: g, blue: b, alpha: 1)
        }
    }

    struct Point: Codable, Equatable {
        enum Value: Codable, Equatable {
            case color(Color)
            case empty
        }
        var value: Value?
    }

    struct Definition: Codable {
        var color: Color
        var n: Int
    }

    var points: [[Point]]

    var horizintals: [[Definition]]
    var verticals: [[Definition]]
    var size: (w: Int, h: Int) {
        return (w: points[0].count, h: points.count)
    }

    var colors: [Color] {
        var result: [String: Color] = [:]
        for def in (horizintals.flatMap({ $0 }) + verticals.flatMap({ $0 })) {
            result[def.color.id] = def.color
        }
        return Array(result.values)
    }
}
