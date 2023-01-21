//
//  SolutionView.swift
//  nonogram
//
//  Created by Denis S. Morozov on 21.01.2023.
//

import Foundation
import UIKit

protocol SolutionViewDelegate: AnyObject {
    func solutionView(_: SolutionView, didTapColumn: Int, row: Int)
    func solutionView(_: SolutionView, didLongTapColumn: Int, row: Int)
}

protocol SolutionViewDataSource: AnyObject {
    func solutionView(_: SolutionView, pointForColumn: Int, row: Int) -> Field.Point
}

class SolutionView: CellView {

    weak var delegate: SolutionViewDelegate?
    weak var dataSource: SolutionViewDataSource?

    private var horizontals: [UIView] = []
    private var verticals: [UIView] = []

    var size: (columns: Int, rows: Int) = (columns: 1, rows: 1) {
        didSet {
            func createView(_ index: Int) -> UIView {
                let v = UIView()
                v.translatesAutoresizingMaskIntoConstraints = false
                v.backgroundColor = ((index + 1) % 5 == 0) ? .black : .gray
                contentView.addSubview(v)
                return v
            }

            horizontals.forEach {
                $0.removeFromSuperview()
            }
            horizontals = (0..<(size.rows - 1)).map { index -> UIView in
                createView(index)
            }

            verticals.forEach {
                $0.removeFromSuperview()
            }
            verticals = (0..<(size.columns - 1)).map { index -> UIView in
                createView(index)
            }

            setNeedsDisplay()
        }
    }

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

            for columnIndex in 0..<solutionView.size.columns {
                for rowIndex in 0..<solutionView.size.rows {
                    let point = solutionView.dataSource!.solutionView(solutionView, pointForColumn: columnIndex, row: rowIndex)
                    switch point.value {
                    case .color(let c):
                        ctx.setFillColor(c.c.cgColor)
                        let rectangle: CGRect = CGRect(
                            x: solutionView.cellAspectSize * CGFloat(columnIndex),
                            y: solutionView.cellAspectSize * CGFloat(rowIndex),
                            width: solutionView.cellAspectSize,
                            height: solutionView.cellAspectSize
                        )
                        ctx.fill(rectangle)
                    case .empty:
                        ctx.setFillColor(UIColor.black.cgColor)
                        let rectangle: CGRect = CGRect(
                            x: solutionView.cellAspectSize * CGFloat(columnIndex) + solutionView.cellAspectSize/2 - 2,
                            y: solutionView.cellAspectSize * CGFloat(rowIndex) + solutionView.cellAspectSize/2 - 2,
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
        delegate?.solutionView(self,
                               didTapColumn: Int(location.x / cellAspectSize),
                               row: Int(location.y / cellAspectSize))
    }

    @objc private func longtap(_ tapGR: UITapGestureRecognizer) {
        let location = tapGR.location(in: self)
        delegate?.solutionView(self,
                               didLongTapColumn: Int(location.x / cellAspectSize),
                               row: Int(location.y / cellAspectSize))
    }
}
