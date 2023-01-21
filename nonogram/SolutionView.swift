//
//  SolutionView.swift
//  nonogram
//
//  Created by Denis S. Morozov on 21.01.2023.
//

import Foundation
import UIKit

protocol SolutionViewDelegate: AnyObject {
    func solutionView(_: SolutionView, didTapI: Int, J: Int)
    func solutionView(_: SolutionView, didLongTapI: Int, J: Int)
}

protocol SolutionViewDataSource: AnyObject {
    func solutionView(_: SolutionView, pointForI: Int, J: Int) -> Field.Point
}

class SolutionView: CellView {

    weak var delegate: SolutionViewDelegate?
    weak var dataSource: SolutionViewDataSource?

    private var horizontals: [UIView] = []
    private var verticals: [UIView] = []

    let w: Int
    let h: Int

    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        cv.setNeedsDisplay()
    }

    init(frame: CGRect, w: Int, h: Int) {

        self.w = w
        self.h = h

        super.init(frame: frame)

        cv.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cv)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: cv.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: cv.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: cv.trailingAnchor),
        ])

        func createView(_ index: Int) -> UIView {
            let v = UIView()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.backgroundColor = ((index + 1) % 5 == 0) ? .black : .gray
            contentView.addSubview(v)
            return v
        }

        horizontals = (0..<(w-1)).map { index -> UIView in
            createView(index)
        }

        verticals = (0..<(h-1)).map { index -> UIView in
            createView(index)
        }

        let tapGR = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        addGestureRecognizer(tapGR)

        let longtapGR = UILongPressGestureRecognizer(target: self, action: #selector(longtap(_:)))
        addGestureRecognizer(longtapGR)

        cv.solutionView = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private class ContentView: UIView {

        unowned var solutionView: SolutionView!

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .white
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draw(_ rect: CGRect) {
            guard let ctx = UIGraphicsGetCurrentContext() else { return }

            for i in 0..<solutionView.h {
                for j in 0..<solutionView.w {
                    let point = solutionView.dataSource!.solutionView(solutionView, pointForI: i, J: j)
                    switch point.value {
                    case .color(let c):
                        ctx.setFillColor(c.c.cgColor)
                        let rectangle: CGRect = CGRect(
                            x: solutionView.cellAspectSize * CGFloat(i),
                            y: solutionView.cellAspectSize * CGFloat(j),
                            width: solutionView.cellAspectSize,
                            height: solutionView.cellAspectSize
                        )
                        ctx.fill(rectangle)
                    case .empty:
                        ctx.setFillColor(UIColor.black.cgColor)
                        let rectangle: CGRect = CGRect(
                            x: solutionView.cellAspectSize * CGFloat(i) + solutionView.cellAspectSize/2 - 2,
                            y: solutionView.cellAspectSize * CGFloat(j) + solutionView.cellAspectSize/2 - 2,
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

    var cellAspectSize: CGFloat = 10 {
        didSet {
            cv.setNeedsLayout()
        }
    }

    private let cv = ContentView()

    override func layoutSubviews() {
        super.layoutSubviews()

        horizontals.enumerated().forEach { i, v in
            let lineWidth: CGFloat = ((i + 1) % 5 == 0) ? 2 : 1

            v.frame = CGRect(
                x: 0,
                y: CGFloat(i + 1) * cellAspectSize,
                width: bounds.width,
                height: lineWidth / UIScreen.main.scale
            )
        }

        verticals.enumerated().forEach { i, v in
            let lineWidth: CGFloat = ((i + 1) % 5 == 0) ? 2 : 1
            v.frame = CGRect(
                x: CGFloat(i + 1) * cellAspectSize,
                y: 0,
                width: lineWidth / UIScreen.main.scale,
                height: bounds.height
            )
        }
    }

    @objc private func tap(_ tapGR: UITapGestureRecognizer) {
        let location = tapGR.location(in: self)
        delegate?.solutionView(self, didTapI: Int(location.x / cellAspectSize), J: Int(location.y / cellAspectSize))
    }

    @objc private func longtap(_ tapGR: UITapGestureRecognizer) {
        let location = tapGR.location(in: self)
        delegate?.solutionView(self, didLongTapI: Int(location.x / cellAspectSize), J: Int(location.y / cellAspectSize))
    }
}
