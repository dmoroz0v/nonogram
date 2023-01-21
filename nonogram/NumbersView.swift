//
//  NumbersView.swift
//  nonogram
//
//  Created by Denis S. Morozov on 13.01.2023.
//

import Foundation
import UIKit

protocol NumbersViewDelegate: AnyObject {
    func numbersView(_: NumbersView, defsForIndex: Int) -> [Field.Point]
}

class NumbersView: CellView {

    weak var delegate: NumbersViewDelegate?

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

            for (defsIndex, line) in numbersView.defs.enumerated() {
                for (defIndex, def) in line.reversed().enumerated() {
                    ctx.setFillColor(def.color.c.cgColor)
                    let cellAspectSize = numbersView.cellAspectSize
                    var rectangle: CGRect
                    if numbersView.axis == .horizontal {
                        rectangle = CGRect(
                            x: cellAspectSize * CGFloat(numbersView.offset - defIndex - 1),
                            y: cellAspectSize * CGFloat(defsIndex),
                            width: cellAspectSize,
                            height: cellAspectSize
                        )
                    } else {
                        rectangle = CGRect(
                            x: cellAspectSize * CGFloat(defsIndex),
                            y: cellAspectSize * CGFloat(numbersView.offset - defIndex - 1),
                            width: cellAspectSize,
                            height: cellAspectSize
                        )
                    }
                    ctx.fill(rectangle)

                    let textColor = def.color.contrastColor
                    
                    if defsIndex == numbersView.focusedIndex {
                        var rectangle = rectangle
                        rectangle = rectangle.insetBy(dx: 1, dy: 1)
                        ctx.setLineWidth(1)
                        ctx.setStrokeColor(textColor.cgColor)
                        ctx.stroke(rectangle)
                    }

                    rectangle.origin.y += 4
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .center
                    let font = UIFont.systemFont(ofSize: 14)
                    let string = NSAttributedString(
                        string: "\(def.n)",
                        attributes: [
                            NSAttributedString.Key.paragraphStyle: paragraphStyle,
                            NSAttributedString.Key.font: font,
                            NSAttributedString.Key.foregroundColor: textColor
                        ])
                    string.draw(in: rectangle)
                }

                if let line = numbersView.delegate?.numbersView(numbersView, defsForIndex: defsIndex) {
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
                            let defs = numbersView.defs[defsIndex]
                            let def = defs[defIndex]
                            if n == def.n {
                                let cellAspectSize = numbersView.cellAspectSize

                                var rectangle: CGRect
                                if numbersView.axis == .horizontal {
                                    rectangle = CGRect(
                                        x: cellAspectSize * CGFloat(numbersView.offset - defs.count + defIndex),
                                        y: cellAspectSize * CGFloat(defsIndex),
                                        width: cellAspectSize,
                                        height: cellAspectSize
                                    )
                                } else {
                                    rectangle = CGRect(
                                        x: cellAspectSize * CGFloat(defsIndex),
                                        y: cellAspectSize * CGFloat(numbersView.offset - defs.count + defIndex),
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

                    defIndex = numbersView.defs[defsIndex].count - 1
                    n = 0
                    for (pointIndex, point) in line.enumerated().reversed() {
                        if point == .init(value: nil) {
                            break
                        }
                        if point != .init(value: .empty) {
                            n += 1
                        }
                        if n != 0 && (pointIndex == 0 || line[pointIndex - 1] != point) {
                            let defs = numbersView.defs[defsIndex]
                            let def = defs[defIndex]
                            if n == def.n {
                                let cellAspectSize = numbersView.cellAspectSize

                                var rectangle: CGRect
                                if numbersView.axis == .horizontal {
                                    rectangle = CGRect(
                                        x: cellAspectSize * CGFloat(numbersView.offset - defs.count + defIndex),
                                        y: cellAspectSize * CGFloat(defsIndex),
                                        width: cellAspectSize,
                                        height: cellAspectSize
                                    )
                                } else {
                                    rectangle = CGRect(
                                        x: cellAspectSize * CGFloat(defsIndex),
                                        y: cellAspectSize * CGFloat(numbersView.offset - defs.count + defIndex),
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
            let defs = numbersView.defs
            let offset = numbersView.offset
            if numbersView.axis == .horizontal {
                let defsIndex = Int(location.y / cellAspectSize)
                let defIndex = Int(location.x / cellAspectSize) - (offset - defs[defsIndex].count)
                if defIndex >= 0 {
                    pickColorHandler?(defs[defsIndex][defIndex].color)
                }
            } else {
                let defsIndex = Int(location.x / cellAspectSize)
                let defIndex = Int(location.y / cellAspectSize) - (offset - defs[defsIndex].count)
                if defIndex >= 0 {
                    pickColorHandler?(defs[defsIndex][defIndex].color)
                }
            }
        }
    }

    var focusedIndex: Int = -1 {
        didSet {
            cv.setNeedsDisplay()
        }
    }

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

    var pickColorHandler: ((_ color: Field.Color) -> Void)? {
        set {
            cv.pickColorHandler = newValue
        }
        get {
            cv.pickColorHandler
        }
    }

    var defs: [[Field.Definition]] = [] {
        didSet {
            cv.setNeedsDisplay()
        }
    }

    private let cv = ContentView()

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

    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        cv.setNeedsDisplay()
    }
}
