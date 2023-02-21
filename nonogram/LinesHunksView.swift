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
    func linesHunksView(_: LinesHunksView, strikedHunksForIndex: Int) -> [Int]
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

                let cellAspectSize = linesHunksView.cellAspectSize

                func rectangle(hunksIndex: Int, hunkIndex: Int) -> CGRect {
                    let space = linesHunksView.space(hunksIndex: hunksIndex)

                    if linesHunksView.axis == .horizontal {
                        return CGRect(
                            x: cellAspectSize * CGFloat(space + hunkIndex),
                            y: cellAspectSize * CGFloat(hunksIndex),
                            width: cellAspectSize,
                            height: cellAspectSize
                        )
                    } else {
                        return CGRect(
                            x: cellAspectSize * CGFloat(hunksIndex),
                            y: cellAspectSize * CGFloat(space + hunkIndex),
                            width: cellAspectSize,
                            height: cellAspectSize
                        )
                    }
                }

                for (hunkIndex, hunk) in lineHunks.enumerated() {

                    var rectangle = rectangle(hunksIndex: hunksIndex, hunkIndex: hunkIndex)

                    // >> Рисуем сплошную заливку клетки
                    ctx.setFillColor(hunk.color.c.cgColor)
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

                    // Проверяем выделена ли эта клетка, и если да то корректируем шрифт на bold
                    if let startSelectedHunk = linesHunksView.startSelectedHunk {
                        let endSelectedHunk = (linesHunksView.endSelectedHunk ?? linesHunksView.startSelectedHunk)!
                        let minColumn = min(startSelectedHunk.column, endSelectedHunk.column)
                        let maxColumn = max(startSelectedHunk.column, endSelectedHunk.column)
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

                // >> Вычеркиваем заполненные
                let strikedHunks = linesHunksView.delegate?.linesHunksView(
                    linesHunksView,
                    strikedHunksForIndex: hunksIndex) ?? []
                for hunkIndex in strikedHunks {
                    let hunk = linesHunksView.linesHunks[hunksIndex][hunkIndex]
                    var rectangle = rectangle(hunksIndex: hunksIndex, hunkIndex: hunkIndex)
                    rectangle = rectangle.insetBy(dx: 2, dy: 2)
                    ctx.setStrokeColor(hunk.color.contrastColor.cgColor)
                    ctx.setLineWidth(1)
                    ctx.move(to: CGPoint(x: rectangle.minX, y: rectangle.minY))
                    ctx.addLine(to: CGPoint(x: rectangle.maxX, y: rectangle.maxY))
                    ctx.strokePath()
                }
                // <<
            }
        }

        @objc private func tap(_ tapGR: UITapGestureRecognizer) {
            let location = tapGR.location(in: self)
            let cellAspectSize = linesHunksView.cellAspectSize
            let linesHunks = linesHunksView.linesHunks
            let hunksIndex: Int
            let hunkIndex: Int
            if linesHunksView.axis == .horizontal {
                hunksIndex = Int(location.y / cellAspectSize)
                hunkIndex = Int(location.x / cellAspectSize) - linesHunksView.space(hunksIndex: hunksIndex)
            } else {
                hunksIndex = Int(location.x / cellAspectSize)
                hunkIndex = Int(location.y / cellAspectSize) - linesHunksView.space(hunksIndex: hunksIndex)
            }
            if hunkIndex >= 0 {
                let pickedColor = linesHunks[hunksIndex][hunkIndex].color
                linesHunksView.showPickColorAnimation(with: pickedColor, lineHunksIndex: hunksIndex, hunkIndex: hunkIndex)
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
            cv.setNeedsDisplay()
        }
    }

    override var intrinsicContentSize: CGSize {
        switch axis {
        case .horizontal:
            return CGSize(
                width: CGFloat(maxHunks) * cellAspectSize,
                height: CGFloat(linesHunks.count) * cellAspectSize)
        case .vertical:
            return CGSize(
                width: CGFloat(linesHunks.count) * cellAspectSize,
                height: CGFloat(maxHunks) * cellAspectSize)
        @unknown default:
            fatalError()
        }
    }

    private let maxHunks: Int

    private let cv = ContentView()

    init(frame: CGRect, panView: UIView, maxHunks: Int) {
        self.maxHunks = maxHunks
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

    private func space(hunksIndex: Int) -> Int {
        return maxHunks - linesHunks[hunksIndex].count
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
                let row = Int(location.y / cellAspectSize)
                startSelectedHunk = (
                    row: row,
                    column: Int(location.x / cellAspectSize) - space(hunksIndex: row)
                )
            case .vertical:
                let row = Int(location.x / cellAspectSize)
                startSelectedHunk = (
                    row: Int(location.x / cellAspectSize),
                    column: Int(location.y / cellAspectSize) - space(hunksIndex: row)
                )
            @unknown default:
                fatalError()
            }
            if startSelectedHunk.column >= 0 {
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
                    column: Int(location.x / cellAspectSize) - space(hunksIndex: startSelectedHunk.row)
                )
            case .vertical:
                endSelectedHunk = (
                    row: startSelectedHunk.row,
                    column: Int(location.y / cellAspectSize) - space(hunksIndex: startSelectedHunk.row)
                )
            @unknown default:
                fatalError()
            }
            if endSelectedHunk.column >= 0 &&
                endSelectedHunk.column < linesHunks[endSelectedHunk.row].count {
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
        let minColumn = min(startSelectedHunk.column, endSelectedHunk.column)
        let maxColumn = max(startSelectedHunk.column, endSelectedHunk.column)

        var prevHunk: Field.LineHunk?
        for columnIndex in minColumn...maxColumn {
            let hunk = linesHunks[startSelectedHunk.row][columnIndex]
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

        let space = space(hunksIndex: startSelectedHunk.row)

        switch axis {
        case .horizontal:
            infoView.center = CGPoint(
                x: CGFloat(space) * cellAspectSize + cellAspectSize * CGFloat(maxColumn + minColumn + 1) / 2,
                y: CGFloat(startSelectedHunk.row) * cellAspectSize - infoView.frame.height / 2
            )
        case .vertical:
            infoView.center = CGPoint(
                x: CGFloat(startSelectedHunk.row) * cellAspectSize - infoView.frame.width / 2,
                y: CGFloat(space) * cellAspectSize + cellAspectSize * CGFloat(maxColumn + minColumn + 1) / 2
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
        let space = space(hunksIndex: lineHunksIndex)
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
