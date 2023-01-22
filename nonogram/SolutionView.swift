//
//  SolutionView.swift
//  nonogram
//
//  Created by Denis S. Morozov on 21.01.2023.
//

import Foundation
import UIKit

protocol SolutionViewDelegate: AnyObject {
    func solutionView(_: SolutionView, didTapColumn: Int, row: Int) -> Bool
    func solutionView(_: SolutionView, didLongTapColumn: Int, row: Int)
}

protocol SolutionViewDataSource: AnyObject {
    func solutionView(_: SolutionView, pointForColumn: Int, row: Int) -> Field.Point
}

class SolutionView: CellView {

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
                    let rectangle: CGRect = CGRect(
                        x: solutionView.cellAspectSize * CGFloat(columnIndex),
                        y: solutionView.cellAspectSize * CGFloat(rowIndex),
                        width: solutionView.cellAspectSize,
                        height: solutionView.cellAspectSize
                    )
                    switch point.value {
                    case .color(let color):
                        ctx.setFillColor(color.c.cgColor)
                        ctx.fill(rectangle)
                        if solutionView.focusedCell?.row == rowIndex,
                           solutionView.focusedCell?.column == columnIndex {
                            ctx.setStrokeColor(color.contrastColor.cgColor)
                            var rectangle = rectangle
                            rectangle = rectangle.insetBy(dx: 1, dy: 1)
                            ctx.setLineWidth(1)
                            ctx.stroke(rectangle)
                        }
                    case .empty:
                        ctx.setFillColor(UIColor.black.cgColor)
                        let circleRect: CGRect = CGRect(
                            x: solutionView.cellAspectSize * CGFloat(columnIndex) + solutionView.cellAspectSize/2 - 2,
                            y: solutionView.cellAspectSize * CGFloat(rowIndex) + solutionView.cellAspectSize/2 - 2,
                            width: 4,
                            height: 4
                        )
                        ctx.fillEllipse(in: circleRect)
                        if solutionView.focusedCell?.row == rowIndex,
                           solutionView.focusedCell?.column == columnIndex {
                            ctx.setStrokeColor(UIColor.gray.cgColor)
                            var rectangle = rectangle
                            rectangle = rectangle.insetBy(dx: 1, dy: 1)
                            ctx.setLineWidth(1)
                            ctx.stroke(rectangle)
                        }
                    case .none:
                        if solutionView.focusedCell?.row == rowIndex,
                           solutionView.focusedCell?.column == columnIndex {
                            ctx.setStrokeColor(UIColor.gray.cgColor)
                            var rectangle = rectangle
                            rectangle = rectangle.insetBy(dx: 1, dy: 1)
                            ctx.setLineWidth(1)
                            ctx.stroke(rectangle)
                        }
                    }
                }
            }
        }

        func showError(row: Int, column: Int) {
            let image = UIImage(named: "error")
            let imageView = UIImageView(image: image)
            imageView.frame.origin = CGPoint(
                x: CGFloat(column) * solutionView.cellAspectSize,
                y: CGFloat(row) * solutionView.cellAspectSize
            )
            addSubview(imageView)
            imageView.transform = .init(scaleX: 0.8, y: 0.8)
            UIView.animate(withDuration: 0.3, animations: {
                imageView.transform = .init(scaleX: 1.2, y: 1.2)
                imageView.alpha = 0
            }, completion: { _ in
                imageView.removeFromSuperview()
            })
        }
    }

    weak var delegate: SolutionViewDelegate?
    weak var dataSource: SolutionViewDataSource?

    private let cv = ContentView()
    private var horizontals: [UIView] = []
    private var verticals: [UIView] = []

    var cellAspectSize: CGFloat = 10 {
        didSet {
            setNeedsDisplay()
        }
    }

    var focusedCell: (row: Int, column: Int)? {
        didSet {
            setNeedsDisplay()
        }
    }

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

        //выключено пока так как конфликт со scrollview
        //let panGR = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        //addGestureRecognizer(panGR)

        let longtapGR = UILongPressGestureRecognizer(target: self, action: #selector(longtap(_:)))
        addGestureRecognizer(longtapGR)

        cv.solutionView = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

    func showError(row: Int, column: Int) {
        cv.showError(row: row, column: column)
    }

    @objc private func tap(_ tapGR: UITapGestureRecognizer) {
        let location = tapGR.location(in: self)
        _ = delegate?.solutionView(self,
                                   didTapColumn: Int(location.x / cellAspectSize),
                                   row: Int(location.y / cellAspectSize))
    }

    private var lastPoint: (row: Int, column: Int)?
    private var stopped = false
    private var startLocation: CGPoint = .zero

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        startLocation = touches.first!.location(in: self)
    }

    @objc private func pan(_ panGR: UIPanGestureRecognizer) {
        switch panGR.state {
        case .possible:
            break
        case .began:
            let newPoint = (row: Int(startLocation.y / cellAspectSize), column: Int(startLocation.x / cellAspectSize))
            lastPoint = newPoint
            stopped = (delegate?.solutionView(self, didTapColumn: newPoint.column, row: newPoint.row)) ?? true
            fallthrough
        case .changed:
            if stopped {
                return
            }
            let location = panGR.location(in: self)
            let newPoint = (row: Int(location.y / cellAspectSize), column: Int(location.x / cellAspectSize))
            if lastPoint?.column != newPoint.column || lastPoint?.row != newPoint.row {
                lastPoint = newPoint
                stopped = (delegate?.solutionView(self, didTapColumn: newPoint.column, row: newPoint.row)) ?? true
            }
        case .ended, .cancelled, .failed:
            lastPoint = nil
            stopped = false
            break
        @unknown default:
            break
        }
    }

    @objc private func longtap(_ tapGR: UITapGestureRecognizer) {
        let location = tapGR.location(in: self)
        delegate?.solutionView(self,
                               didLongTapColumn: Int(location.x / cellAspectSize),
                               row: Int(location.y / cellAspectSize))
    }
}
