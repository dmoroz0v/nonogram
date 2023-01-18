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

        var pickColorHandler: ((_ color: Field.Color) -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .white

            let tapGR = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
            addGestureRecognizer(tapGR)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draw(_ rect: CGRect) {
            guard let ctx = UIGraphicsGetCurrentContext() else { return }

            for (j, line) in numbers.enumerated() {
                for (i, def) in line.reversed().enumerated() {
                    ctx.setFillColor(def.color.c.cgColor)
                    var rectangle: CGRect
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

                    rectangle.origin.y += 3
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .center
                    let font = UIFont.systemFont(ofSize: 12)
                    let string = NSAttributedString(
                        string: "\(def.n)",
                        attributes: [
                            NSAttributedString.Key.paragraphStyle: paragraphStyle,
                            NSAttributedString.Key.font: font,
                            NSAttributedString.Key.foregroundColor: textColor
                        ])
                    string.draw(in: rectangle)
                }
            }
        }

        @objc private func tap(_ tapGR: UITapGestureRecognizer) {
            let location = tapGR.location(in: self)
            if axis == .horizontal {
                let row = Int(location.y / cellAspectSize)
                let column = Int(location.x / cellAspectSize) - (offset - numbers[row].count)
                if column >= 0 {
                    pickColorHandler?(numbers[row][column].color)
                }
            } else {
                let row = Int(location.x / cellAspectSize)
                let column = Int(location.y / cellAspectSize) - (offset - numbers[row].count)
                if column >= 0 {
                    pickColorHandler?(numbers[row][column].color)
                }
            }
        }
    }

    var pickColorHandler: ((_ color: Field.Color) -> Void)? {
        set {
            cv.pickColorHandler = newValue
        }
        get {
            cv.pickColorHandler
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
