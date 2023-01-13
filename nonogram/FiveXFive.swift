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
