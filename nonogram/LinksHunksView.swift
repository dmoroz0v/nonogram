//
//  LinesHunksView.swift
//  nonogram
//
//  Created by Denis S. Morozov on 13.01.2023.
//

import Foundation
import UIKit
import UIKit.UIGestureRecognizerSubclass

protocol LinesHunksViewDelegate: AnyObject {
    func linesHunksView(_: LinesHunksView, lineForIndex: Int) -> [Field.Value?]
}

final class LinesHunksView: CellView {

    weak var delegate: LinesHunksViewDelegate?

    private final class ContentView: UIView {

        unowned var linesHunksView: LinesHunksView!

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

            for (hunksIndex, lineHunks) in linesHunksView.linesHunks.enumerated() {
                for (hunkIndex, hunk) in lineHunks.enumerated() {
                    let space = linesHunksView.maxHunks - linesHunksView.linesHunks[hunksIndex].count
                    let cellAspectSize = linesHunksView.cellAspectSize
                    var rectangle: CGRect

                    // >> Рисуем сплошную заливку клетки
                    ctx.setFillColor(hunk.color.c.cgColor)
                    if linesHunksView.axis == .horizontal {
                        rectangle = CGRect(
                            x: cellAspectSize * CGFloat(space + hunkIndex),
                            y: cellAspectSize * CGFloat(hunksIndex),
                            width: cellAspectSize,
                            height: cellAspectSize
                        )
                    } else {
                        rectangle = CGRect(
                            x: cellAspectSize * CGFloat(hunksIndex),
                            y: cellAspectSize * CGFloat(space + hunkIndex),
                            width: cellAspectSize,
                            height: cellAspectSize
                        )
                    }
                    ctx.fill(rectangle)
                    // <<

                    let contrastColor = hunk.color.contrastColor

                    // >> Рисуем обводку
                    if hunksIndex == linesHunksView.focusedIndex {
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
                    if let startSelectedHunk = linesHunksView.startSelectedHunk {
                        let endSelectedHunk = (linesHunksView.endSelectedHunk ?? linesHunksView.startSelectedHunk)!
                        let minColumn = min(startSelectedHunk.column, endSelectedHunk.column) - space
                        let maxColumn = max(startSelectedHunk.column, endSelectedHunk.column) - space
                        if hunksIndex == startSelectedHunk.row && hunkIndex >= minColumn && hunkIndex <= maxColumn {
                            font = UIFont.systemFont(ofSize: 0.62 * cellAspectSize, weight: .heavy)
                            rectangle.origin.y -= 1
                        }
                    }
                    let string = NSAttributedString(
                        string: "\(hunk.n)",
                        attributes: [
                            NSAttributedString.Key.paragraphStyle: paragraphStyle,
                            NSAttributedString.Key.font: font,
                            NSAttributedString.Key.foregroundColor: contrastColor
                        ])
                    string.draw(in: rectangle)
                    // <<
                }

                if let line = linesHunksView.delegate?.linesHunksView(linesHunksView, lineForIndex: hunksIndex) {
                    // >> проходимся от начала линии до конца и пытаемся вычеркнуть цифры слева или сверху
                    strikeHunks(ctx: ctx,
                                line: line,
                                range: Array(0..<line.count),
                                hunkStartIndex: 0,
                                increment: 1,
                                hunksIndex: hunksIndex)
                    // <<

                    // >> проходимся от конца линии до начала и пытаемся вычеркнуть цифры справа или снизу
                    strikeHunks(ctx: ctx,
                                line: line,
                                range: (0..<line.count).reversed(),
                                hunkStartIndex: linesHunksView.linesHunks[hunksIndex].count - 1,
                                increment: -1,
                                hunksIndex: hunksIndex)
                    // <<
                }
            }
        }

        private func strikeHunks(
            ctx: CGContext,
            line: [Field.Value?],
            range: [Int],
            hunkStartIndex: Int,
            increment: Int,
            hunksIndex: Int
        ) {
            var hunkIndex = hunkStartIndex
            var n = 0
            for valueIndex in range {
                let value = line[valueIndex]
                if value == nil {
                    break
                }
                if value != .empty {
                    n += 1
                }
                if n != 0
                    && (valueIndex + 1 == line.count || valueIndex == 0 || line[valueIndex + increment] != value)
                    && hunkIndex >= 0 && hunkIndex < linesHunksView.linesHunks[hunksIndex].count
                {
                    let lineHunks = linesHunksView.linesHunks[hunksIndex]
                    let hunk = lineHunks[hunkIndex]
                    if n == hunk.n {
                        let cellAspectSize = linesHunksView.cellAspectSize

                        var rectangle: CGRect
                        if linesHunksView.axis == .horizontal {
                            rectangle = CGRect(
                                x: cellAspectSize * CGFloat(linesHunksView.maxHunks - lineHunks.count + hunkIndex),
                                y: cellAspectSize * CGFloat(hunksIndex),
                                width: cellAspectSize,
                                height: cellAspectSize
                            )
                        } else {
                            rectangle = CGRect(
                                x: cellAspectSize * CGFloat(hunksIndex),
                                y: cellAspectSize * CGFloat(linesHunksView.maxHunks - lineHunks.count + hunkIndex),
                                width: cellAspectSize,
                                height: cellAspectSize
                            )
                        }
                        rectangle = rectangle.insetBy(dx: 2, dy: 2)
                        ctx.setStrokeColor(hunk.color.contrastColor.cgColor)
                        ctx.setLineWidth(1)
                        ctx.move(to: CGPoint(x: rectangle.minX, y: rectangle.minY))
                        ctx.addLine(to: CGPoint(x: rectangle.maxX, y: rectangle.maxY))
                        ctx.strokePath()

                        n = 0
                        hunkIndex += increment
                    }
                }
            }
        }

        @objc private func tap(_ tapGR: UITapGestureRecognizer) {
            let location = tapGR.location(in: self)
            let cellAspectSize = linesHunksView.cellAspectSize
            let linesHunks = linesHunksView.linesHunks
            let maxColumns = linesHunksView.maxHunks
            let lineHunksIndex: Int
            let hunkIndex: Int
            if linesHunksView.axis == .horizontal {
                lineHunksIndex = Int(location.y / cellAspectSize)
                hunkIndex = Int(location.x / cellAspectSize) - (maxColumns - linesHunks[lineHunksIndex].count)
            } else {
                lineHunksIndex = Int(location.x / cellAspectSize)
                hunkIndex = Int(location.y / cellAspectSize) - (maxColumns - linesHunks[lineHunksIndex].count)
            }
            if hunkIndex >= 0 {
                let pickedColor = linesHunks[lineHunksIndex][hunkIndex].color
                linesHunksView.showPickColorAnimation(with: pickedColor, lineHunksIndex: lineHunksIndex, hunkIndex: hunkIndex)
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

    var pickColorHandler: ((_ color: Field.Color) -> Void)? {
        set {
            cv.pickColorHandler = newValue
        }
        get {
            cv.pickColorHandler
        }
    }

    var linesHunks: [[Field.LineHunk]] = [] {
        didSet {
            maxHunks = linesHunks.reduce(0, { partialResult, lineHunks in
                if lineHunks.count > partialResult {
                    return lineHunks.count
                } else {
                    return partialResult
                }
            })
            invalidateIntrinsicContentSize()
            cv.setNeedsDisplay()
        }
    }

    override var intrinsicContentSize: CGSize {
        switch axis {
        case .horizontal:
            return CGSize(width: CGFloat(maxHunks) * cellAspectSize, height: CGFloat(linesHunks.count) * cellAspectSize)
        case .vertical:
            return CGSize(width: CGFloat(linesHunks.count) * cellAspectSize, height: CGFloat(maxHunks) * cellAspectSize)
        @unknown default:
            fatalError()
        }
    }

    private var maxHunks: Int = 0

    private let cv = ContentView()

    init(frame: CGRect, panView: UIView) {
        super.init(frame: frame)
        cv.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cv)

        cv.linesHunksView = self

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

    private var startSelectedHunk: (row: Int, column: Int)?
    private var endSelectedHunk: (row: Int, column: Int)?

    @objc private func longPressPan(_ gr: LongPressPanGR) {
        switch gr.state {
        case .possible:
            break
        case .began:
            let location = gr.location(in: self)
            let startSelectedHunk: (row: Int, column: Int)
            switch axis {
            case .horizontal:
                startSelectedHunk = (
                    row: Int(location.y / cellAspectSize),
                    column: Int(location.x / cellAspectSize)
                )
            case .vertical:
                startSelectedHunk = (
                    row: Int(location.x / cellAspectSize),
                    column: Int(location.y / cellAspectSize)
                )
            @unknown default:
                fatalError()
            }
            let space = maxHunks - linesHunks[startSelectedHunk.row].count
            if startSelectedHunk.column >= space {
                self.startSelectedHunk = startSelectedHunk
            }
        case .changed:
            guard let startSelectedHunk = startSelectedHunk else {
                return
            }
            let location = gr.location(in: self)
            let endSelectedHunk: (row: Int, column: Int)
            switch axis {
            case .horizontal:
                endSelectedHunk = (
                    row: startSelectedHunk.row,
                    column: Int(location.x / cellAspectSize)
                )
            case .vertical:
                endSelectedHunk = (
                    row: startSelectedHunk.row,
                    column: Int(location.y / cellAspectSize)
                )
            @unknown default:
                fatalError()
            }
            let adustColumnIndex = maxHunks - linesHunks[endSelectedHunk.row].count
            if endSelectedHunk.column >= adustColumnIndex &&
                endSelectedHunk.column < maxHunks {
                self.endSelectedHunk = endSelectedHunk
            }
        case .ended, .cancelled:
            startSelectedHunk = nil
            endSelectedHunk = nil
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
        guard let startSelectedHunk = startSelectedHunk else {
            infoView.removeFromSuperview()
            sumLabel.removeFromSuperview()
            setNeedsDisplay()
            return
        }
        let endSelectedHunk = endSelectedHunk ?? startSelectedHunk

        var n = 0
        let space = (maxHunks - linesHunks[startSelectedHunk.row].count)
        let minColumn = min(startSelectedHunk.column, endSelectedHunk.column)
        let maxColumn = max(startSelectedHunk.column, endSelectedHunk.column)

        var prevHunk: Field.LineHunk?
        for columnIndex in minColumn...maxColumn {
            let hunk = linesHunks[startSelectedHunk.row][columnIndex - space]
            n += hunk.n
            if hunk.color.id == prevHunk?.color.id {
                n += 1
            }
            prevHunk = hunk
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
                y: CGFloat(startSelectedHunk.row) * cellAspectSize - infoView.frame.height / 2
            )
        case .vertical:
            infoView.center = CGPoint(
                x: CGFloat(startSelectedHunk.row) * cellAspectSize - infoView.frame.width / 2,
                y: cellAspectSize * CGFloat(maxColumn + minColumn + 1) / 2
            )
        @unknown default:
            break
        }

        setNeedsDisplay()
    }

    private var showPickColorAnimationContext: NSObject?

    private func showPickColorAnimation(with color: Field.Color, lineHunksIndex: Int, hunkIndex: Int) {
        addSubview(infoView)
        infoView.alpha = 1
        infoView.backgroundColor = color.c
        let space = maxHunks - linesHunks[lineHunksIndex].count
        switch axis {
        case .horizontal:
            infoView.center = CGPoint(
                x: cellAspectSize * CGFloat(hunkIndex + space) + cellAspectSize / 2,
                y: CGFloat(lineHunksIndex) * cellAspectSize - infoView.frame.height / 2
            )
        case .vertical:
            infoView.center = CGPoint(
                x: CGFloat(lineHunksIndex) * cellAspectSize - infoView.frame.width / 2,
                y: cellAspectSize * CGFloat(hunkIndex + space) + cellAspectSize / 2
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

extension LinesHunksView: LongPressPanGRDelegate {
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
