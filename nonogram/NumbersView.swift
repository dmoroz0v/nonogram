//
//  NumbersView.swift
//  nonogram
//
//  Created by Denis S. Morozov on 13.01.2023.
//

import Foundation
import UIKit

class NumbersView: CellView {

    var axis: NSLayoutConstraint.Axis = .horizontal {
        didSet {
            cv.axis = axis
        }
    }

    var cellAspectSize: CGFloat = 1 {
        didSet {
            cv.cellAspectSize = cellAspectSize
        }
    }

    var offset: Int = 0 {
        didSet {
            cv.offset = offset
        }
    }

    private class ContentView: UIView {

        var axis: NSLayoutConstraint.Axis = .horizontal {
            didSet {
                setNeedsDisplay()
            }
        }

        var cellAspectSize: CGFloat = 1 {
            didSet {
                setNeedsDisplay()
            }
        }

        var numbers: [[Field.Definition]] = [] {
            didSet {
                setNeedsDisplay()
            }
        }

        var offset: Int = 0 {
            didSet {
                setNeedsDisplay()
            }
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .white
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draw(_ rect: CGRect) {
            guard let ctx = UIGraphicsGetCurrentContext() else { return }

            for (j, line) in numbers.enumerated() {
                for (i, def) in line.reversed().enumerated() {
                    ctx.setFillColor(def.color.c.cgColor)
                    let rectangle: CGRect
                    if axis == .horizontal {
                        rectangle = CGRect(
                            x: cellAspectSize * CGFloat(offset - i - 1),
                            y: cellAspectSize * CGFloat(j),
                            width: cellAspectSize,
                            height: cellAspectSize
                        )
                    } else {
                        rectangle = CGRect(
                            x: cellAspectSize * CGFloat(j),
                            y: cellAspectSize * CGFloat(offset - i - 1),
                            width: cellAspectSize,
                            height: cellAspectSize
                        )
                    }
                    ctx.fill(rectangle)

                    var white: CGFloat = 0
                    var alpha: CGFloat = 0
                    def.color.c.getWhite(&white, alpha: &alpha)

                    if white > 0.5 {
                        white = 0
                    } else {
                        white = 1
                    }

                    let textColor = UIColor(white: white, alpha: alpha)

                    let font = UIFont.systemFont(ofSize: 12)
                    let string = NSAttributedString(
                        string: "\(def.n)",
                        attributes: [
                            NSAttributedString.Key.font: font,
                            NSAttributedString.Key.foregroundColor: textColor
                        ])
                    string.draw(at: CGPoint(
                        x: rectangle.origin.x + 7,
                        y: rectangle.origin.y + 3
                    ))
                }
            }
        }
    }

    var numbers: [[Field.Definition]] = [] {
        didSet {
            cv.numbers = numbers
        }
    }

    private let cv = ContentView()

    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        cv.setNeedsDisplay()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        cv.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cv)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: cv.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: cv.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: cv.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
