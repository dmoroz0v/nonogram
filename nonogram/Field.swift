//
//  Field.swift
//  nonogram
//
//  Created by Denis S. Morozov on 12.01.2023.
//

import Foundation
import UIKit

struct Field {
    struct Color {
        var c: UIColor
        var id: String {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            c.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return "\(Int(red*255))-\(Int(green*255))-\(Int(blue*255))-\(Int(alpha*255))"
        }
    }

    struct Point {
        enum Value {
            case color(Color)
            case empty
        }
        var value: Value?
    }

    struct Definition {
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
