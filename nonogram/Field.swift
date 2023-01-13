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
            let rgb = rgb.split(separator: " ")
            assert(rgb.count == 3)
            c = UIColor(red: CGFloat(Int(rgb[0])!)/255, green: CGFloat(Int(rgb[1])!)/255, blue: CGFloat(Int(rgb[2])!)/255, alpha: 1)
            id = rgb[0] + " " + rgb[1] + " " + rgb[2]
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
            let rgb = id.split(separator: " ")
            c = UIColor(red: CGFloat(Int(rgb[0])!)/255, green: CGFloat(Int(rgb[1])!)/255, blue: CGFloat(Int(rgb[2])!)/255, alpha: 1)
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
