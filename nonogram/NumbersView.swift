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
                    let cellAspectSize = numbersView.cellAspectSize
                    var rectangle: CGRect

                    // >> Рисуем сплошную заливку клетки
                    ctx.setFillColor(def.color.c.cgColor)
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
                    // <<

                    let contrastColor = def.color.contrastColor

                    // >> Рисуем обводку
                    if defsIndex == numbersView.focusedIndex {
                        var rectangle = rectangle
                        rectangle = rectangle.insetBy(dx: 1, dy: 1)
                        ctx.setLineWidth(1)
                        ctx.setStrokeColor(contrastColor.cgColor)
                        ctx.stroke(rectangle)
                    }
                    // <<

                    // >> Рисуем цифру
                    rectangle.origin.y += 0.16 * cellAspectSize
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .center
                    var font = UIFont.systemFont(ofSize: 0.58 * cellAspectSize)
                    if let startSelectedDef = numbersView.startSelectedDef {
                        let endSelectedDef = (numbersView.endSelectedDef ?? numbersView.startSelectedDef)!
                        let minColumn = min(startSelectedDef.column, endSelectedDef.column) - space
                        let maxColumn = max(startSelectedDef.column, endSelectedDef.column) - space
                        if defsIndex == startSelectedDef.row && defIndex >= minColumn && defIndex <= maxColumn {
                            font = UIFont.systemFont(ofSize: 0.62 * cellAspectSize, weight: .heavy)
                            rectangle.origin.y -= 1
                        }
                    }
                    let string = NSAttributedString(
                        string: "\(def.n)",
                        attributes: [
                            NSAttributedString.Key.paragraphStyle: paragraphStyle,
                            NSAttributedString.Key.font: font,
                            NSAttributedString.Key.foregroundColor: contrastColor
                        ])
                    string.draw(in: rectangle)
                    // <<
                }

                if let line = numbersView.delegate?.numbersView(numbersView, defsForIndex: defsIndex) {
                    // >> проходимся от начала линии до конца и пытаемся вычеркнуть цифры слева или сверху
                    strikeDefs(ctx: ctx,
                               line: line,
                               range: Array(0..<line.count),
                               defStartIndex: 0,
                               increment: 1,
                               defsIndex: defsIndex)
                    // <<

                    // >> проходимся от конца линии до начала и пытаемся вычеркнуть цифры справа или снизу
                    strikeDefs(ctx: ctx,
                               line: line,
                               range: (0..<line.count).reversed(),
                               defStartIndex: numbersView.defs[defsIndex].count - 1,
                               increment: -1,
                               defsIndex: defsIndex)
                    // <<
                }
            }
        }

        private func strikeDefs(
            ctx: CGContext,
            line: [Field.Point],
            range: [Int],
            defStartIndex: Int,
            increment: Int,
            defsIndex: Int
        ) {
            var defIndex = defStartIndex
            var n = 0
            for pointIndex in range {
                let point = line[pointIndex]
                if point == .undefined {
                    break
                }
                if point != .empty {
                    n += 1
                }
                if n != 0 && (pointIndex + 1 == line.count || pointIndex == 0 || line[pointIndex + increment] != point) {
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
                        rectangle = rectangle.insetBy(dx: 2, dy: 2)
                        ctx.setStrokeColor(def.color.contrastColor.cgColor)
                        ctx.setLineWidth(1)
                        ctx.move(to: CGPoint(x: rectangle.minX, y: rectangle.minY))
                        ctx.addLine(to: CGPoint(x: rectangle.maxX, y: rectangle.maxY))
                        ctx.strokePath()

                        n = 0
                        defIndex += increment
                    }
                }
            }
        }

        @objc private func tap(_ tapGR: UITapGestureRecognizer) {
            let location = tapGR.location(in: self)
            let cellAspectSize = numbersView.cellAspectSize
            let defs = numbersView.defs
            let offset = numbersView.offset
            let defsIndex: Int
            let defIndex: Int
            if numbersView.axis == .horizontal {
                defsIndex = Int(location.y / cellAspectSize)
                defIndex = Int(location.x / cellAspectSize) - (offset - defs[defsIndex].count)
            } else {
                defsIndex = Int(location.x / cellAspectSize)
                defIndex = Int(location.y / cellAspectSize) - (offset - defs[defsIndex].count)
            }
            if defIndex >= 0 {
                let pickedColor = defs[defsIndex][defIndex].color
                numbersView.showPickColorAnimation(with: pickedColor, defsIndex: defsIndex, defIndex: defIndex)
                pickColorHandler?(pickedColor)
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

    init(frame: CGRect, panView: UIView) {
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
        longPressPanGR.longPressPanDelegate = self
        panView.addGestureRecognizer(longPressPanGR)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        cv.setNeedsDisplay()
    }

    private var startSelectedDef: (row: Int, column: Int)?
    private var endSelectedDef: (row: Int, column: Int)?

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

    private lazy var infoView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.shadowOpacity = 0.2
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowRadius = 4
        v.layer.cornerRadius = 4
        v.frame.size = CGSize(width: 24, height: 24)
        return v
    }()

    private lazy var sumLabel: UILabel = {
        let l = UILabel()
        l.backgroundColor = .clear
        l.textAlignment = .center
        l.font = UIFont.systemFont(ofSize: 16)
        return l
    }()

    func drawSum() {
        guard let startSelectedDef = startSelectedDef else {
            infoView.removeFromSuperview()
            sumLabel.removeFromSuperview()
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

        if infoView.superview == nil {
            addSubview(infoView)
        }
        infoView.backgroundColor = .white
        infoView.alpha = 1
        infoView.addSubview(sumLabel)
        sumLabel.frame.size = infoView.frame.size
        sumLabel.text = "\(n)"

        switch axis {
        case .horizontal:
            infoView.center = CGPoint(
                x: cellAspectSize * CGFloat(maxColumn + minColumn + 1) / 2,
                y: CGFloat(startSelectedDef.row) * cellAspectSize - infoView.frame.height / 2
            )
        case .vertical:
            infoView.center = CGPoint(
                x: CGFloat(startSelectedDef.row) * cellAspectSize - infoView.frame.width / 2,
                y: cellAspectSize * CGFloat(maxColumn + minColumn + 1) / 2
            )
        @unknown default:
            break
        }

        setNeedsDisplay()
    }

    private var showPickColorAnimationContext: NSObject?

    private func showPickColorAnimation(with color: Field.Color, defsIndex: Int, defIndex: Int) {
        addSubview(infoView)
        infoView.alpha = 1
        infoView.backgroundColor = color.c
        let space = offset - defs[defsIndex].count
        switch axis {
        case .horizontal:
            infoView.center = CGPoint(
                x: cellAspectSize * CGFloat(defIndex + space) + cellAspectSize / 2,
                y: CGFloat(defsIndex) * cellAspectSize - infoView.frame.height / 2
            )
        case .vertical:
            infoView.center = CGPoint(
                x: CGFloat(defsIndex) * cellAspectSize - infoView.frame.width / 2,
                y: cellAspectSize * CGFloat(defIndex + space) + cellAspectSize / 2
            )
        @unknown default:
            break
        }

        setNeedsDisplay()

        let showPickColorAnimationContext = NSObject()

        UIView.animateKeyframes(withDuration: 0.25, delay: 0.5, animations: {
            self.infoView.alpha = 0
        }, completion: { _ in
            if showPickColorAnimationContext === self.showPickColorAnimationContext {
                self.infoView.removeFromSuperview()
                self.infoView.alpha = 1
            }
        })
    }
}

extension NumbersView: LongPressPanGRDelegate {
    fileprivate func longPressPanGRIsPossibeRecognize(_ gr: LongPressPanGR) -> Bool {
        let point = gr.location(in: self)
        return bounds.contains(point)
    }
}

private protocol LongPressPanGRDelegate: AnyObject {
    func longPressPanGRIsPossibeRecognize(_: LongPressPanGR) -> Bool
}

private final class LongPressPanGR: UIGestureRecognizer {
    weak var longPressPanDelegate: LongPressPanGRDelegate?
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
        let isPossibleRecognize = longPressPanDelegate?.longPressPanGRIsPossibeRecognize(self) ?? true
        guard isPossibleRecognize else {
            state = .failed
            timer?.invalidate()
            timer = nil
            return
        }
        processingTouch = touches.first
        startPoint = touches.first!.location(in: view)
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
        if state == .possible && point.distance(to: startPoint) < 6 {
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
