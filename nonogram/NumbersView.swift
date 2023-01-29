//
//  NumbersView.swift
//  nonogram
//
//  Created by Denis S. Morozov on 13.01.2023.
//

import Foundation
import UIKit
import UIKit.UIGestureRecognizerSubclass

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
                for (defIndex, def) in line.enumerated() {
                    let space = numbersView.offset - numbersView.defs[defsIndex].count
                    ctx.setFillColor(def.color.c.cgColor)
                    let cellAspectSize = numbersView.cellAspectSize
                    var rectangle: CGRect
                    if numbersView.axis == .horizontal {
                        rectangle = CGRect(
                            x: cellAspectSize * CGFloat(space + defIndex),
                            y: cellAspectSize * CGFloat(defsIndex),
                            width: cellAspectSize,
                            height: cellAspectSize
                        )
                    } else {
                        rectangle = CGRect(
                            x: cellAspectSize * CGFloat(defsIndex),
                            y: cellAspectSize * CGFloat(space + defIndex),
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
                    var font = UIFont.systemFont(ofSize: 14)
                    if let startSelectedDef = numbersView.startSelectedDef {
                        let endSelectedDef = (numbersView.endSelectedDef ?? numbersView.startSelectedDef)!
                        let minColumn = min(startSelectedDef.column, endSelectedDef.column) - space
                        let maxColumn = max(startSelectedDef.column, endSelectedDef.column) - space
                        if defsIndex == startSelectedDef.row && defIndex >= minColumn && defIndex <= maxColumn {
                            font = UIFont.systemFont(ofSize: 15, weight: .heavy)
                            rectangle.origin.y -= 1
                        }
                    }
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
                        if point == .undefined {
                            break
                        }
                        if point != .empty {
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
                        if point == .undefined {
                            break
                        }
                        if point != .empty {
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

        let longPressPanGR = LongPressPanGR(target: self, action: #selector(longPressPan(_:)))
        addGestureRecognizer(longPressPanGR)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        cv.setNeedsDisplay()
    }

    var startSelectedDef: (row: Int, column: Int)?
    var endSelectedDef: (row: Int, column: Int)?

    @objc private func longPressPan(_ gr: LongPressPanGR) {
        switch gr.state {
        case .possible:
            break
        case .began:
            let location = gr.location(in: self)
            let startSelectedDef: (row: Int, column: Int)
            switch axis {
            case .horizontal:
                startSelectedDef = (
                    row: Int(location.y / cellAspectSize),
                    column: Int(location.x / cellAspectSize)
                )
            case .vertical:
                startSelectedDef = (
                    row: Int(location.x / cellAspectSize),
                    column: Int(location.y / cellAspectSize)
                )
            @unknown default:
                fatalError()
            }
            let space = offset - defs[startSelectedDef.row].count
            if startSelectedDef.column >= space {
                self.startSelectedDef = startSelectedDef
            }
        case .changed:
            guard let startSelectedDef = startSelectedDef else {
                return
            }
            let location = gr.location(in: self)
            let endSelectedDef: (row: Int, column: Int)
            switch axis {
            case .horizontal:
                endSelectedDef = (
                    row: startSelectedDef.row,
                    column: Int(location.x / cellAspectSize)
                )
            case .vertical:
                endSelectedDef = (
                    row: startSelectedDef.row,
                    column: Int(location.y / cellAspectSize)
                )
            @unknown default:
                fatalError()
            }
            let adustColumnIndex = offset - defs[endSelectedDef.row].count
            if endSelectedDef.column >= adustColumnIndex &&
                endSelectedDef.column < offset {
                self.endSelectedDef = endSelectedDef
            }
        case .ended, .cancelled:
            startSelectedDef = nil
            endSelectedDef = nil
        case .failed:
            break
        @unknown default:
            break
        }

        drawSum()
    }

    private lazy var sumLabelView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.shadowOpacity = 0.2
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowRadius = 4
        return v
    }()

    private lazy var sumLabel: UILabel = {
        let l = UILabel()
        l.backgroundColor = .white
        l.layer.cornerRadius = 4
        l.layer.masksToBounds = true
        l.textAlignment = .center
        l.font = UIFont.systemFont(ofSize: 16)
        sumLabelView.addSubview(l)
        return l
    }()

    func drawSum() {
        guard let startSelectedDef = startSelectedDef else {
            sumLabelView.removeFromSuperview()
            setNeedsDisplay()
            return
        }
        let endSelectedDef = endSelectedDef ?? startSelectedDef

        var n = 0
        let space = (offset - defs[startSelectedDef.row].count)
        let minColumn = min(startSelectedDef.column, endSelectedDef.column)
        let maxColumn = max(startSelectedDef.column, endSelectedDef.column)

        var prevDef: Field.Definition?
        for columnIndex in minColumn...maxColumn {
            let def = defs[startSelectedDef.row][columnIndex - space]
            n += def.n
            if def.color.id == prevDef?.color.id {
                n += 1
            }
            prevDef = def
        }

        if sumLabelView.superview == nil {
            cv.addSubview(sumLabelView)
        }
        sumLabelView.frame.size = CGSize(width: cellAspectSize, height: cellAspectSize)
        sumLabel.frame.size = CGSize(width: cellAspectSize, height: cellAspectSize)
        sumLabel.text = "\(n)"

        switch axis {
        case .horizontal:
            sumLabelView.center = CGPoint(
                x: cellAspectSize * CGFloat(maxColumn + minColumn) / 2 + cellAspectSize/2,
                y: CGFloat(startSelectedDef.row) * cellAspectSize - cellAspectSize / 2
            )
        case .vertical:
            sumLabelView.center = CGPoint(
                x: CGFloat(startSelectedDef.row) * cellAspectSize - cellAspectSize / 2,
                y: cellAspectSize * CGFloat(maxColumn + minColumn) / 2 + cellAspectSize/2
            )
        @unknown default:
            break
        }

        setNeedsDisplay()
    }
}

class LongPressPanGR: UIGestureRecognizer {
    private var timer: Timer?
    private var processingTouch: UITouch?
    private var startPoint: CGPoint?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.numberOfTouches == 2 {
            state = .failed
            timer?.invalidate()
            timer = nil
            return
        }
        processingTouch = touches.first
        startPoint = processingTouch?.location(in: view)
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            if self.timer != nil {
                self.timer?.invalidate()
                self.timer = nil

                self.state = .began
            } else {
                self.state = .failed
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let processingTouch = processingTouch,
              touches.contains(processingTouch),
              let startPoint = startPoint else {
            state = .failed
            timer?.invalidate()
            timer = nil
            return
        }

        let point = processingTouch.location(in: view)
        if state == .possible && point.distance(to: startPoint) < 2 {
            return
        }

        if state == .began || state == .changed {
            state = .changed
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if state == .began || state == .changed {
            state = .ended
        }
        timer?.invalidate()
        timer = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if state == .began || state == .changed {
            state = .cancelled
        }
        timer?.invalidate()
        timer = nil
    }
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow((point.x - x), 2) + pow((point.y - y), 2))
    }
}
