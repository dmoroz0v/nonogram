//
//  NumbersView.swift
//  nonogram
//
//  Created by Denis S. Morozov on 13.01.2023.
//

import Foundation
import UIKit

protocol NumbersViewDelegate: AnyObject {
    func numbersView(_: NumbersView, line: Int) -> [Field.Point]
}

class NumbersView: CellView {

    weak var delegate: NumbersViewDelegate?

    var axis: NSLayoutConstraint.Axis = .horizontal {
        didSet {
            cv.setNeedsDisplay()
        }
    }

    var cellAspectSize: CGFloat = 1 {
        didSet {
            cv.setNeedsDisplay()
        }
    }

    var offset: Int = 0 {
        didSet {
            cv.setNeedsDisplay()
        }
    }

    private class ContentView: UIView {

        unowned var numbersView: NumbersView!

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

            for (j, line) in numbersView.numbers.enumerated() {
                for (i, def) in line.reversed().enumerated() {
                    ctx.setFillColor(def.color.c.cgColor)
                    let cellAspectSize = numbersView.cellAspectSize
                    var rectangle: CGRect
                    if numbersView.axis == .horizontal {
                        rectangle = CGRect(
                            x: cellAspectSize * CGFloat(numbersView.offset - i - 1),
                            y: cellAspectSize * CGFloat(j),
                            width: cellAspectSize,
                            height: cellAspectSize
                        )
                    } else {
                        rectangle = CGRect(
                            x: cellAspectSize * CGFloat(j),
                            y: cellAspectSize * CGFloat(numbersView.offset - i - 1),
                            width: cellAspectSize,
                            height: cellAspectSize
                        )
                    }
                    ctx.fill(rectangle)

                    let textColor = def.color.contrastColor

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

                if let line = numbersView.delegate?.numbersView(numbersView, line: j) {
                    var defIndex = 0
                    var n = 0
                    for (pointIndex, point) in line.enumerated() {
                        if point == .init(value: nil) {
                            break
                        }
                        if point != .init(value: .empty) {
                            n += 1
                        }
                        if n != 0 && (pointIndex + 1 == line.count || line[pointIndex + 1] != point) {
                            let numbers = numbersView.numbers[j]
                            let def = numbers[defIndex]
                            if n == def.n {
                                let cellAspectSize = numbersView.cellAspectSize

                                var rectangle: CGRect
                                if numbersView.axis == .horizontal {
                                    rectangle = CGRect(
                                        x: cellAspectSize * CGFloat(numbersView.offset - numbers.count + defIndex),
                                        y: cellAspectSize * CGFloat(j),
                                        width: cellAspectSize,
                                        height: cellAspectSize
                                    )
                                } else {
                                    rectangle = CGRect(
                                        x: cellAspectSize * CGFloat(j),
                                        y: cellAspectSize * CGFloat(numbersView.offset - numbers.count + defIndex),
                                        width: cellAspectSize,
                                        height: cellAspectSize
                                    )
                                }
                                ctx.setStrokeColor(def.color.contrastColor.cgColor)
                                ctx.setLineWidth(1)
                                ctx.move(to: CGPoint(x: rectangle.minX, y: rectangle.minY))
                                ctx.addLine(to: CGPoint(x: rectangle.maxX, y: rectangle.maxY))
                                ctx.strokePath()

                                n = 0
                                defIndex += 1
                            }
                        }
                    }

                    defIndex = numbersView.numbers[j].count - 1
                    n = 0
                    for (pointIndex, point) in line.reversed().enumerated() {
                        if point == .init(value: nil) {
                            break
                        }
                        if point != .init(value: .empty) {
                            n += 1
                        }
                        if n != 0 && (pointIndex == 0 || line[pointIndex - 1] != point) {
                            let numbers = numbersView.numbers[j]
                            let def = numbers[defIndex]
                            if n == def.n {
                                let cellAspectSize = numbersView.cellAspectSize

                                var rectangle: CGRect
                                if numbersView.axis == .horizontal {
                                    rectangle = CGRect(
                                        x: cellAspectSize * CGFloat(numbersView.offset - numbers.count + defIndex),
                                        y: cellAspectSize * CGFloat(j),
                                        width: cellAspectSize,
                                        height: cellAspectSize
                                    )
                                } else {
                                    rectangle = CGRect(
                                        x: cellAspectSize * CGFloat(j),
                                        y: cellAspectSize * CGFloat(numbersView.offset - numbers.count + defIndex),
                                        width: cellAspectSize,
                                        height: cellAspectSize
                                    )
                                }
                                ctx.setStrokeColor(def.color.contrastColor.cgColor)
                                ctx.setLineWidth(1)
                                ctx.move(to: CGPoint(x: rectangle.minX, y: rectangle.minY))
                                ctx.addLine(to: CGPoint(x: rectangle.maxX, y: rectangle.maxY))
                                ctx.strokePath()

                                n = 0
                                defIndex -= 1
                            }
                        }
                    }
                }
            }
        }

        @objc private func tap(_ tapGR: UITapGestureRecognizer) {
            let location = tapGR.location(in: self)
            let cellAspectSize = numbersView.cellAspectSize
            let numbers = numbersView.numbers
            let offset = numbersView.offset
            if numbersView.axis == .horizontal {
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
            cv.setNeedsDisplay()
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

        cv.numbersView = self

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
