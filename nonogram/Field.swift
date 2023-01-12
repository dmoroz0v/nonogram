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
        var id: String

        init(rgb: String) {
            id = rgb
            let rgb = rgb.split(separator: " ")
            c = UIColor(red: CGFloat(Int(rgb[0])!)/255, green: CGFloat(Int(rgb[1])!)/255, blue: CGFloat(Int(rgb[2])!)/255, alpha: 1)
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
