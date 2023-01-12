//
//  FiveXFive.swift
//  nonogram
//
//  Created by Denis S. Morozov on 12.01.2023.
//

import Foundation
import UIKit

protocol FiveXFiveDelegate: AnyObject {
    func fiveXFive(_: FiveXFive, didTapI: Int, J: Int)
    func fiveXFive(_: FiveXFive, pointForI: Int, J: Int) -> Field.Point
}

class FiveXFive: CellView {

    weak var delegate: FiveXFiveDelegate?

    private var horizontals: [UIView] = []
    private var verticals: [UIView] = []

    var i: Int = 0
    var j: Int = 0

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

        func createView() -> UIView {
            let v = UIView()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.backgroundColor = .black
            contentView.addSubview(v)
            return v
        }

        horizontals = [
            createView(),
            createView(),
            createView(),
            createView(),
        ]

        verticals = [
            createView(),
            createView(),
            createView(),
            createView(),
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private class ContentView: UIView {

        unowned var fiveXfive: FiveXFive!

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .white
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draw(_ rect: CGRect) {
            guard let ctx = UIGraphicsGetCurrentContext() else { return }

            for i in 0..<5 {
                for j in 0..<5 {
                    let point = fiveXfive.delegate!.fiveXFive(fiveXfive, pointForI: i, J: j)
                    switch point.value {
                    case .color(let c):
                        ctx.setFillColor(c.c.cgColor)
                        let rectangle: CGRect = CGRect(
                            x: fiveXfive.cellAspectSize * CGFloat(i),
                            y: fiveXfive.cellAspectSize * CGFloat(j),
                            width: fiveXfive.cellAspectSize,
                            height: fiveXfive.cellAspectSize
                        )
                        ctx.fill(rectangle)
                    case .empty:
                        ctx.setFillColor(UIColor.black.cgColor)
                        let rectangle: CGRect = CGRect(
                            x: fiveXfive.cellAspectSize * CGFloat(i) + fiveXfive.cellAspectSize/2 - 2,
                            y: fiveXfive.cellAspectSize * CGFloat(j) + fiveXfive.cellAspectSize/2 - 2,
                            width: 4,
                            height: 4
                        )
                        ctx.fillEllipse(in: rectangle)
                    case .none:
                        break
                    }
                }
            }
        }
    }

    let cellAspectSize: CGFloat = 20

    private let cv = ContentView()

    override func layoutSubviews() {
        super.layoutSubviews()

        horizontals.enumerated().forEach { i, v in
            v.frame = CGRect(
                x: 0,
                y: CGFloat(i + 1) * (bounds.height / 5),
                width: bounds.width,
                height: 1/UIScreen.main.scale
            )
        }

        verticals.enumerated().forEach { i, v in
            v.frame = CGRect(
                x: CGFloat(i + 1) * (bounds.height / 5),
                y: 0,
                width: 1/UIScreen.main.scale,
                height: bounds.height
            )
        }

        let tapGR = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        addGestureRecognizer(tapGR)

        cv.fiveXfive = self
    }

    @objc private func tap(_ tapGR: UITapGestureRecognizer) {
        let location = tapGR.location(in: self)
        delegate?.fiveXFive(self, didTapI: Int(location.x / cellAspectSize), J: Int(location.y / cellAspectSize))
        cv.setNeedsDisplay()
    }
}

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

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .white
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draw(_ rect: CGRect) {
            guard let ctx = UIGraphicsGetCurrentContext() else { return }

            let max = numbers.reduce(0) { partialResult, line in
                if line.count > partialResult {
                    return line.count
                }
                return partialResult
            }

            for (j, line) in numbers.enumerated() {
                for (i, def) in line.reversed().enumerated() {
                    ctx.setFillColor(def.color.c.cgColor)
                    let rectangle: CGRect
                    if axis == .horizontal {
                        rectangle = CGRect(
                            x: cellAspectSize * CGFloat(max - i - 1),
                            y: cellAspectSize * CGFloat(j),
                            width: cellAspectSize,
                            height: cellAspectSize
                        )
                    } else {
                        rectangle = CGRect(
                            x: cellAspectSize * CGFloat(j),
                            y: cellAspectSize * CGFloat(max - i - 1),
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
