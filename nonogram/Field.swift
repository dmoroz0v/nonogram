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
        var contrastColor: UIColor

        init(rgb: String) {
            id = rgb
            c = Color.color(hex: id)
            contrastColor = Color.contrastColor(from: c)
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
            c = Color.color(hex: id)
            contrastColor = Color.contrastColor(from: c)
        }

        static func contrastColor(from color: UIColor) -> UIColor {
            var white: CGFloat = 0
            var alpha: CGFloat = 0
            color.getWhite(&white, alpha: &alpha)

            if white > 0.65 {
                white = 0
            } else {
                white = 1
            }

            return UIColor(white: white, alpha: alpha)
        }

        static func color(hex: String) -> UIColor {
            let scanner = Scanner(string: hex)
            var hexNumber: UInt64 = 0

            scanner.scanHexInt64(&hexNumber)
            let r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
            let g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
            let b = CGFloat((hexNumber & 0x0000ff) >> 0) / 255

            return UIColor(red: r, green: g, blue: b, alpha: 1)
        }
    }

    enum Value: Codable, Equatable {
        case color(Color)
        case empty

        var contrastColor: UIColor {
            switch self {
            case .color(let c):
                return c.contrastColor
            case .empty:
                return UIColor.gray
            }
        }
    }

    struct LineHunk: Codable {
        var color: Color
        var n: Int
    }

    var values: [[Value?]]

    var horizintalLinesHunks: [[LineHunk]]
    var verticalLinesHunks: [[LineHunk]]
    var colors: [Color]
    var size: (columns: Int, rows: Int) {
        return (columns: values[0].count, rows: values.count)
    }
}
