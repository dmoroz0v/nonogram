//
//  FieldView.swift
//  nonogram
//
//  Created by Denis S. Morozov on 29.01.2023.
//

import Foundation
import UIKit

final class FieldView: UIView, PanGRDelegate {
    private let cellAspectSize: CGFloat = 24
    private let size: (columns: Int, rows: Int)

    private(set) var horizontalDefsCell: NumbersView!
    private(set) var verticalDefsCell: NumbersView!
    let solutionView = SolutionView()

    init(frame: CGRect, field: Field) {
        size = field.size
        super.init(frame: frame)

        horizontalDefsCell = NumbersView(frame: .zero, panView: self)
        verticalDefsCell = NumbersView(frame: .zero, panView: self)

        let maxHorizintalDefs = field.horizintals.reduce(0) { value, defs in
            if defs.count > value {
                return defs.count
            }
            return value
        }
        let maxVerticalDefs = field.verticals.reduce(0) { value, defs in
            if defs.count > value {
                return defs.count
            }
            return value
        }

        let leftTopCell = CellView()
        leftTopCell.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftTopCell)

        horizontalDefsCell.translatesAutoresizingMaskIntoConstraints = false
        horizontalDefsCell.cellAspectSize = cellAspectSize
        horizontalDefsCell.defs = field.horizintals
        horizontalDefsCell.offset = maxHorizintalDefs
        horizontalDefsCell.axis = .horizontal
        addSubview(horizontalDefsCell)

        verticalDefsCell.translatesAutoresizingMaskIntoConstraints = false
        verticalDefsCell.cellAspectSize = cellAspectSize
        verticalDefsCell.defs = field.verticals
        verticalDefsCell.offset = maxVerticalDefs
        verticalDefsCell.axis = .vertical
        addSubview(verticalDefsCell)

        solutionView.translatesAutoresizingMaskIntoConstraints = false
        solutionView.size = field.size
        solutionView.cellAspectSize = cellAspectSize
        addSubview(solutionView)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(
                equalToConstant: CGFloat(maxHorizintalDefs + field.size.columns) * cellAspectSize),
            heightAnchor.constraint(
                equalToConstant: CGFloat(maxVerticalDefs + field.size.rows) * cellAspectSize),

            leftTopCell.topAnchor.constraint(equalTo: topAnchor),
            leftTopCell.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftTopCell.widthAnchor.constraint(equalToConstant: CGFloat(maxHorizintalDefs) * cellAspectSize),
            leftTopCell.heightAnchor.constraint(equalToConstant: CGFloat(maxVerticalDefs) * cellAspectSize),

            horizontalDefsCell.topAnchor.constraint(equalTo: leftTopCell.bottomAnchor),
            horizontalDefsCell.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalDefsCell.bottomAnchor.constraint(equalTo: bottomAnchor),
            horizontalDefsCell.widthAnchor.constraint(equalToConstant: CGFloat(maxHorizintalDefs) * cellAspectSize),

            verticalDefsCell.topAnchor.constraint(equalTo: topAnchor),
            verticalDefsCell.leadingAnchor.constraint(equalTo: leftTopCell.trailingAnchor),
            verticalDefsCell.trailingAnchor.constraint(equalTo: trailingAnchor),
            verticalDefsCell.heightAnchor.constraint(equalToConstant: CGFloat(maxVerticalDefs) * cellAspectSize),

            solutionView.topAnchor.constraint(equalTo: verticalDefsCell.bottomAnchor),
            solutionView.leadingAnchor.constraint(equalTo: horizontalDefsCell.trailingAnchor),
            solutionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            solutionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        let panGR = PanGR(target: self, action: #selector(pan(_:)))
        panGR.panGRView = solutionView
        panGR.panGRdelegate = self
        addGestureRecognizer(panGR)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            let newPoint = (
                row: Int(panGR.startPoint!.y / cellAspectSize),
                column: Int((panGR.startPoint!.x / cellAspectSize))
            )
            lastPoint = newPoint
            stopped = (solutionView.delegate?.solutionView(solutionView, didTouchColumn: newPoint.column, row: newPoint.row)) ?? true
            fallthrough
        case .changed:
            if stopped {
                return
            }
            let location = panGR.location(in: solutionView)
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

            if self.direction != direction {
                return
            }
            let step = direction.delta
            var point = lastPoint!
            while point != nextPoint {
                point.row += step.dRow
                point.column += step.dColumn
                if point.column < 0 || point.row < 0 ||
                    point.row >= size.rows || point.column >= size.columns {
                    stopped = true
                    break
                } else {
                    stopped = (solutionView.delegate?.solutionView(
                        solutionView,
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

    fileprivate func panGRIsPossibleRecognize(_ panGR: PanGR) -> Bool {
        let location = panGR.location(in: solutionView)
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
    weak var panGRView: UIView?

    private var processingTouch: UITouch?
    private(set) var startPoint: CGPoint?
    private(set) var startDate: Date?

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
        startPoint = processingTouch?.location(in: panGRView)
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

        let point = processingTouch.location(in: panGRView)
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
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow((point.x - x), 2) + pow((point.y - y), 2))
    }
}
