//
//  SolutionView.swift
//  nonogram
//
//  Created by Denis S. Morozov on 21.01.2023.
//

import Foundation
import UIKit
import UIKit.UIGestureRecognizerSubclass

protocol SolutionViewDelegate: AnyObject {
    func solutionView(_: SolutionView, didTouchColumn: Int, row: Int) -> Bool
    func solutionView(_: SolutionView, didLongTapColumn: Int, row: Int)
}

protocol SolutionViewDataSource: AnyObject {
    func solutionView(_: SolutionView, pointForColumn: Int, row: Int) -> Field.Point
    func solutionView(_: SolutionView, validValueForColumn: Int, row: Int) -> Field.Point.Value
    func solutionViewNeedShowsErrors(_: SolutionView) -> Bool
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
                    case .empty:
                        ctx.setFillColor(UIColor.black.cgColor)
                        let circleRect: CGRect = CGRect(
                            x: solutionView.cellAspectSize * CGFloat(columnIndex) + solutionView.cellAspectSize/2 - 0.1 * solutionView.cellAspectSize,
                            y: solutionView.cellAspectSize * CGFloat(rowIndex) + solutionView.cellAspectSize/2 - 0.1 * solutionView.cellAspectSize,
                            width: 0.2 * solutionView.cellAspectSize,
                            height: 0.2 * solutionView.cellAspectSize
                        )
                        ctx.fillEllipse(in: circleRect)
                    case .none:
                        break
                    }

                    if solutionView.focusedCell?.row == rowIndex,
                       solutionView.focusedCell?.column == columnIndex {

                        let ficusedCellInsets = UIEdgeInsets(
                            top: 3/UIScreen.main.scale,
                            left: 3/UIScreen.main.scale,
                            bottom: 2/UIScreen.main.scale,
                            right: 2/UIScreen.main.scale
                        )

                        ctx.setStrokeColor(point.contrastColor.cgColor)
                        var rectangle = rectangle
                        rectangle = rectangle.inset(by: ficusedCellInsets)
                        ctx.setLineWidth(1)
                        ctx.stroke(rectangle)
                    }

                    if let value = point.value, solutionView.dataSource!.solutionViewNeedShowsErrors(solutionView) {
                        let validValue = solutionView.dataSource!.solutionView(solutionView, validValueForColumn: columnIndex, row: rowIndex)
                        if validValue != value {
                            let cellAspectSize = solutionView.cellAspectSize

                            var rectangle = CGRect(
                                x: cellAspectSize * CGFloat(columnIndex),
                                y: cellAspectSize * CGFloat(rowIndex),
                                width: cellAspectSize,
                                height: cellAspectSize
                            )
                            rectangle = rectangle.insetBy(dx: 2, dy: 2)
                            ctx.setStrokeColor(value.contrastColor.cgColor)
                            ctx.setLineWidth(1)
                            ctx.move(to: CGPoint(x: rectangle.minX, y: rectangle.minY))
                            ctx.addLine(to: CGPoint(x: rectangle.maxX, y: rectangle.maxY))
                            ctx.strokePath()
                            ctx.move(to: CGPoint(x: rectangle.maxX, y: rectangle.minY))
                            ctx.addLine(to: CGPoint(x: rectangle.minX, y: rectangle.maxY))
                            ctx.strokePath()
                        }
                    }
                }
            }
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

    init(frame: CGRect, panView: UIView) {
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

        let hoverGR = UIHoverGestureRecognizer(target: self, action: #selector(hover(_:)))
        addGestureRecognizer(hoverGR)

        cv.solutionView = self

        let panGR = PanGR(target: self, action: #selector(pan(_:)))
        panGR.panGRdelegate = self
        panView.addGestureRecognizer(panGR)
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

    @objc private func tap(_ tapGR: UITapGestureRecognizer) {
        let location = tapGR.location(in: self)
        _ = delegate?.solutionView(self,
                                   didTouchColumn: Int(location.x / cellAspectSize),
                                   row: Int(location.y / cellAspectSize))
    }

    @objc private func longtap(_ tapGR: UITapGestureRecognizer) {
        let location = tapGR.location(in: self)
        delegate?.solutionView(self,
                               didLongTapColumn: Int(location.x / cellAspectSize),
                               row: Int(location.y / cellAspectSize))
    }

    @objc private func hover(_ hoverGR: UIHoverGestureRecognizer) {
        let location = hoverGR.location(in: self)
        delegate?.solutionView(self,
                               didLongTapColumn: Int(location.x / cellAspectSize),
                               row: Int(location.y / cellAspectSize))
    }

    private var lastPoint: (row: Int, column: Int)?
    private var stopped = false
    private var direction: Direction?
    private enum Direction {
        case up, down, left, right

        var delta: (dRow: Int, dColumn: Int) {
            switch self {
            case .up: return (dRow: -1, dColumn: 0)
            case .down: return (dRow: 1, dColumn: 0)
            case .left: return (dRow: 0, dColumn: -1)
            case .right: return (dRow: 0, dColumn: 1)
            }
        }
    }

    @objc private func pan(_ panGR: PanGR) {
        switch panGR.state {
        case .possible:
            break
        case .began:
            let startPoint = panGR.startPoint(in: self)!
            let newPoint = (
                row: Int(startPoint.y / cellAspectSize),
                column: Int((startPoint.x / cellAspectSize))
            )
            lastPoint = newPoint
            stopped = (delegate?.solutionView(self, didTouchColumn: newPoint.column, row: newPoint.row)) ?? true
            fallthrough
        case .changed:
            if stopped {
                return
            }
            let location = panGR.location(in: self)
            let nextPoint = (
                row: Int(location.y / cellAspectSize),
                column: Int(location.x / cellAspectSize)
            )
            var newDirection: Direction?
            let delta = (
                horizontal: nextPoint.column - lastPoint!.column,
                vertical: nextPoint.row - lastPoint!.row
            )
            if abs(delta.horizontal) > abs(delta.vertical) {
                if delta.horizontal != 0 {
                    if delta.horizontal < 0 {
                        newDirection = .left
                    } else {
                        newDirection = .right
                    }
                }
            } else {
                if delta.vertical != 0 {
                    if delta.vertical < 0 {
                        newDirection = .up
                    } else {
                        newDirection = .down
                    }
                }
            }

            if self.direction == nil {
                self.direction = newDirection
            }

            guard let direction = self.direction, direction == newDirection else {
                return
            }

            let step = direction.delta
            func comparePoint(_ p1: (row: Int, column: Int), to p2: (row: Int, column: Int), direction: Direction) -> Bool {
                switch direction {
                case .up, .down: return p1.row == p2.row
                case .left, .right: return p1.column == p2.column
                }
            }
            var point = lastPoint!
            while !comparePoint(point, to: nextPoint, direction: direction) {
                point.row += step.dRow
                point.column += step.dColumn
                if point.column < 0 || point.row < 0 ||
                    point.row >= size.rows || point.column >= size.columns {
                    stopped = true
                    break
                } else {
                    stopped = (delegate?.solutionView(
                        self,
                        didTouchColumn: point.column,
                        row: point.row)) ?? true
                    if stopped {
                        break
                    }
                    lastPoint = point
                }
            }
        case .ended, .cancelled, .failed:
            lastPoint = nil
            stopped = false
            direction = nil
            break
        @unknown default:
            break
        }
    }
}

extension SolutionView: PanGRDelegate {
    fileprivate func panGRIsPossibleRecognize(_ panGR: PanGR) -> Bool {
        let location = panGR.location(in: self)
        if location.x < 0 || location.y < 0 {
            return false
        }
        return true
    }
}

private protocol PanGRDelegate: AnyObject {
    func panGRIsPossibleRecognize(_: PanGR) -> Bool
}

private final class PanGR: UIGestureRecognizer {

    weak var panGRdelegate: PanGRDelegate?
    private var startPoint: CGPoint?

    private var processingTouch: UITouch?
    private var startDate: Date?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let isPossibleRecognize = panGRdelegate?.panGRIsPossibleRecognize(self) ?? true
        if !isPossibleRecognize {
            state = .failed
            return
        }
        if self.numberOfTouches == 2 {
            state = .failed
            return
        }
        startDate = Date()
        processingTouch = touches.first
        startPoint = processingTouch?.location(in: view)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.numberOfTouches == 2 {
            state = .failed
            return
        }
        guard Date.timeIntervalSinceReferenceDate - startDate!.timeIntervalSinceReferenceDate > 0.1 else {
            return
        }
        guard let processingTouch = processingTouch,
              touches.contains(processingTouch),
              let startPoint = startPoint else {
            state = .failed
            return
        }

        let point = processingTouch.location(in: view)
        if state == .possible && point.distance(to: startPoint) < 6 {
            return
        }

        if state == .possible {
            state = .began
        } else if state == .began || state == .changed {
            state = .changed
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if state == .began || state == .changed {
            state = .ended
        }
        startPoint = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if state == .began || state == .changed {
            state = .cancelled
        }
        startPoint = nil
    }

    func startPoint(in view: UIView) -> CGPoint? {
        guard let startPoint else {
            return nil
        }
        return view.convert(startPoint, from: self.view)
    }
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow((point.x - x), 2) + pow((point.y - y), 2))
    }
}
