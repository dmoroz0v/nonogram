//
//  ResolvingViewController.swift
//  nonogram
//
//  Created by Denis S. Morozov on 12.01.2023.
//

import Foundation
import UIKit

enum Pen {
    case empty
    case color(Field.Color)
    case layer(Field.Color)
}

protocol ResolvingViewControllerDelegate: AnyObject {
    func resolvingViewController(
        _: ResolvingViewController,
        didChangeState: Field,
        layers: [String: Field],
        currentLayer: String?,
        solution: [[Int]],
        colors: [Field.Color],
        url: URL
    )

    func resolvingViewControllerDidTapExit(_: ResolvingViewController)
}

class ResolvingViewController: UIViewController, UIPencilInteractionDelegate {

    enum UpdateAction {
        case selectLayer(penColor: Field.Color)
        case selectPen(pen: Pen)
        case closeLayerAndSelectPen(pen: Pen)
    }

    weak var delegate: ResolvingViewControllerDelegate?

    // views
    private let scrollView = UIScrollView()
    private let contentView = CellView()
    private let controlsPanelView = ControlsPanelView()
    private var fieldView: FieldView!

    private var controlsPanelViewHotizontal: NSLayoutConstraint?
    private var controlsPanelViewVertical: NSLayoutConstraint?

    private let url: URL
    private let solution: [[Int]]
    private let colors: [Field.Color]
    private var field: Field!
    private var sourceField: Field!
    private var layers: [String: Field] = [:]
    private var layerColorId: String?
    private var prevPens: [Pen] = []
    private var pen: Pen = .empty {
        didSet {
            prevPens.append(oldValue)
            if prevPens.count == 11 {
                prevPens = Array(prevPens.dropFirst(1))
            }
            controlsPanelView.pen = pen
        }
    }

    init(
        url: URL,
        horizontalDefs: [[Field.Definition]],
        verticalDefs: [[Field.Definition]],
        solution: [[Int]],
        colors: [Field.Color]
    ) {
        self.url = url
        field = Field(
            points: Array<[Field.Point]>(
                repeating: Array<Field.Point>(repeating: .undefined, count: verticalDefs.count),
                count: horizontalDefs.count
            ),
            horizintals: horizontalDefs,
            verticals: verticalDefs
        )
        self.solution = solution
        self.colors = colors
        super.init(nibName: nil, bundle: nil)
    }

    init(
        url: URL,
        field: Field,
        layers: [String: Field],
        currentLayer: String?,
        solution: [[Int]],
        colors: [Field.Color]
    ) {
        self.url = url
        self.field = field
        self.layers = layers
        self.layerColorId = currentLayer
        if let currentLayer = currentLayer {
            self.sourceField = field
            self.field = layers[currentLayer]
        }
        self.solution = solution
        self.colors = colors
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
        scrollView.maximumZoomScale = 5
        scrollView.delegate = self
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.clipsToBounds = true
        scrollView.addSubview(contentView)
        scrollView.contentInset = .init(top: 60, left: 40, bottom: 60, right: 40)

        let field: Field! = (sourceField ?? field)

        fieldView = FieldView(frame: .zero, field: field)
        fieldView.translatesAutoresizingMaskIntoConstraints = false

        fieldView.horizontalDefsCell.delegate = self
        fieldView.horizontalDefsCell.pickColorHandler = { [weak self] color in
            self?.update(with: .selectPen(pen: .color(color)))
        }

        fieldView.verticalDefsCell.delegate = self
        fieldView.verticalDefsCell.pickColorHandler = { [weak self] color in
            self?.update(with: .selectPen(pen: .color(color)))
        }

        fieldView.solutionView.delegate = self
        fieldView.solutionView.dataSource = self

        contentView.contentView.addSubview(fieldView)

        controlsPanelView.translatesAutoresizingMaskIntoConstraints = false
        controlsPanelView.colors = field.colors
        controlsPanelView.delegate = self
        view.addSubview(controlsPanelView)

        let controlsPanelViewPanGR = UIPanGestureRecognizer(
            target: self,
            action: #selector(controlsPanelViewPan(_:))
        )
        controlsPanelView.addGestureRecognizer(controlsPanelViewPanGR)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),

            fieldView.topAnchor.constraint(equalTo: contentView.contentView.topAnchor),
            fieldView.leadingAnchor.constraint(equalTo: contentView.contentView.leadingAnchor),
            fieldView.trailingAnchor.constraint(equalTo: contentView.contentView.trailingAnchor),
            fieldView.bottomAnchor.constraint(equalTo: contentView.contentView.bottomAnchor),

            {
                controlsPanelViewHotizontal = controlsPanelView.trailingAnchor.constraint(
                    equalTo: view.trailingAnchor)
                return controlsPanelViewHotizontal!
            }(),
            {
                controlsPanelViewVertical = controlsPanelView.centerYAnchor.constraint(
                    equalTo: view.centerYAnchor)
                return controlsPanelViewVertical!
            }(),
        ])

        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = self
        view.addInteraction(pencilInteraction)

        applyState()
    }

    func strikeEmptyCellsIfResolved(row: Int) {
        var rowIsResolved = true
        for columnIndex in 0..<field.size.columns {
            if let layerColorId = layerColorId {
                let index = colors.firstIndex { $0.id == layerColorId }! + 1
                if field.points[row][columnIndex] == .undefined && solution[row][columnIndex] == index {
                    rowIsResolved = false
                }
            } else if field.points[row][columnIndex] == .undefined && solution[row][columnIndex] > 0 {
                rowIsResolved = false
            }
        }
        if rowIsResolved {
            for columnIndex in 0..<field.size.columns {
                if field.points[row][columnIndex] == .undefined {
                    field.points[row][columnIndex] = .empty
                }
            }
        }
    }

    func strikeEmptyCellsIfResolved(column: Int) {
        var columnIsResolved = true
        for rowIndex in 0..<field.size.rows {
            if let layerColorId = layerColorId {
                let index = colors.firstIndex { $0.id == layerColorId }! + 1
                if field.points[rowIndex][column] == .undefined && solution[rowIndex][column] == index {
                    columnIsResolved = false
                }
            } else if field.points[rowIndex][column] == .undefined && solution[rowIndex][column] > 0 {
                columnIsResolved = false
            }
        }
        if columnIsResolved {
            for rowIndex in 0..<field.size.rows {
                if field.points[rowIndex][column] == .undefined {
                    field.points[rowIndex][column] = .empty
                }
            }
        }
    }

    func update(with action: UpdateAction) {
        switch action {
        case .selectLayer(let penColor):
            self.pen = .layer(penColor)
            sourceField = field
            if layers[penColor.id] == nil {
                layers[penColor.id] = Field(
                    points: field.points.map({ row in
                        var row = row
                        for (rowIndex, point) in row.enumerated() {
                            if case .color(let c) = point.value, c.id != penColor.id {
                                row[rowIndex] = .empty
                            }
                        }
                        return row
                    }),
                    horizintals: sourceField.horizintals.map({ defs in
                        return defs.filter { def in
                            def.color.id == penColor.id
                        }
                    }),
                    verticals: sourceField.verticals.map({ defs in
                        return defs.filter { def in
                            def.color.id == penColor.id
                        }
                    })
                )
            }

            field = layers[penColor.id]

            for (rowIndex, row) in sourceField.points.enumerated() {
                for (columnIndex, point) in row.enumerated() {
                    if field.horizintals[rowIndex].isEmpty || field.verticals[columnIndex].isEmpty {
                        field.points[rowIndex][columnIndex] = .empty
                        continue
                    }
                    if case .color(let c) = point.value {
                        if c.id == penColor.id {
                            field.points[rowIndex][columnIndex] = point
                        } else {
                            field.points[rowIndex][columnIndex] = .empty
                        }
                    }
                    if point == .empty {
                        field.points[rowIndex][columnIndex] = point
                    }
                }
            }

            layerColorId = penColor.id

            for rowIndex in 0..<field.size.rows {
                strikeEmptyCellsIfResolved(row: rowIndex)
            }
            for columnIndex in 0..<field.size.columns {
                strikeEmptyCellsIfResolved(column: columnIndex)
            }
        case .closeLayerAndSelectPen(let pen):
            self.pen = pen

            layers[layerColorId!] = field
            field = sourceField
            sourceField = nil

            for (rowIndex, row) in layers[layerColorId!]!.points.enumerated() {
                for (columnIndex, point) in row.enumerated() {
                    if case .color(let c) = point.value, c.id == layerColorId {
                        field.points[rowIndex][columnIndex] = point
                    }
                }
            }

            layerColorId = nil

            for rowIndex in 0..<field.size.rows {
                strikeEmptyCellsIfResolved(row: rowIndex)
            }
            for columnIndex in 0..<field.size.columns {
                strikeEmptyCellsIfResolved(column: columnIndex)
            }

        case .selectPen(let pen):
            self.pen = pen
        }

        applyState()

        delegate?.resolvingViewController(
            self,
            didChangeState: sourceField ?? field,
            layers: layers,
            currentLayer: layerColorId,
            solution: solution,
            colors: colors,
            url: url
        )
    }

    func applyState() {
        fieldView.solutionView.setNeedsDisplay()
        fieldView.horizontalDefsCell.defs = field.horizintals
        fieldView.horizontalDefsCell.setNeedsDisplay()
        fieldView.verticalDefsCell.defs = field.verticals
        fieldView.verticalDefsCell.setNeedsDisplay()

        if layerColorId == nil {
            controlsPanelView.showCommon()
        } else {
            controlsPanelView.showLayer(color: field.colors.first(where: { $0.id == layerColorId })!)
        }
    }

    private var controlsPanelViewPanPrevLocation: CGPoint?
    @objc private func controlsPanelViewPan(_ panGR: UIPanGestureRecognizer) {
        switch panGR.state {
        case .possible:
            break
        case .began, .changed:
            if let controlsPanelViewPanPrevLocation = self.controlsPanelViewPanPrevLocation {
                let newPoint = panGR.location(in: view)
                controlsPanelViewHotizontal!.constant += (newPoint.x - controlsPanelViewPanPrevLocation.x)
                controlsPanelViewVertical!.constant += (newPoint.y - controlsPanelViewPanPrevLocation.y)
                self.controlsPanelViewPanPrevLocation = newPoint
            } else {
                controlsPanelViewPanPrevLocation = panGR.location(in: view)
            }
        case .ended, .cancelled, .failed:
            controlsPanelViewPanPrevLocation = nil
        @unknown default:
            break
        }
    }

    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        switch pen {
        case .empty:
            if let layerColorId {
                pen = .layer(colors.first(where: { $0.id == layerColorId })!)
            } else {
                let prevDoloredPen = prevPens.reversed().first { prevPen in
                    switch prevPen {
                    case .empty: return false
                    case .color, .layer: return true
                    }
                }
                switch prevDoloredPen {
                case .empty, .none:
                    pen = .color(colors.first!)
                case .color(let c):
                    pen = .color(c)
                case .layer(let c):
                    pen = .color(c)
                }
            }
        case .color, .layer:
            pen = .empty
        }
    }

}

extension ResolvingViewController: NumbersViewDelegate {
    func numbersView(_ numbersView: NumbersView, defsForIndex index: Int) -> [Field.Point] {
        if numbersView.axis == .horizontal {
            let row = index
            return field.points[row]
        } else {
            let column = index
            var result: [Field.Point] = []
            for rowIndex in 0..<field.size.rows {
                result.append(field.points[rowIndex][column])
            }
            return result
        }
    }
}

extension ResolvingViewController: ControlsPanelViewDelegate {
    func controlsPanelViewDidTapExit(_: ControlsPanelView) {
        delegate?.resolvingViewControllerDidTapExit(self)
    }

    func controlsPanelViewDidSelctColorForCurrentLayer(_: ControlsPanelView, color: Field.Color) {
        pen = .layer(color)
    }

    func controlsPanelViewDidCloseLayer(_: ControlsPanelView) {
        if case .layer(let c) = pen {
            update(with: .closeLayerAndSelectPen(pen: .color(c)))
        } else {
            update(with: .closeLayerAndSelectPen(pen: .empty))
        }
    }

    func controlsPanelViewPresentingViewController(_: ControlsPanelView) -> UIViewController {
        return self
    }

    func controlsPanelView(_: ControlsPanelView, didSelectPen pen: Pen) {
        if case .layer(let penColor) = pen {
            update(with: .selectLayer(penColor: penColor))
        } else {
            update(with: .selectPen(pen: pen))
        }
    }
}

extension ResolvingViewController: SolutionViewDelegate, SolutionViewDataSource {
    func solutionView(_ solutionView: SolutionView, pointForColumn column: Int, row: Int) -> Field.Point {
        return field.points[row][column]
    }

    func solutionView(_ solutionView: SolutionView, didLongTapColumn column: Int, row: Int) {
        fieldView.horizontalDefsCell.focusedIndex = row
        fieldView.verticalDefsCell.focusedIndex = column
        solutionView.focusedCell = (row: row, column: column)
    }

    func solutionView(_ solutionView: SolutionView, didTouchColumn column: Int, row: Int) -> Bool {
        if field.points[row][column] != .undefined {
            return true
        }

        var newValue: Field.Point
        switch pen {
        case .empty:
            newValue = .empty
        case .color(let c):
            newValue = .init(value: .color(c))
        case .layer(let c):
            newValue = .init(value: .color(c))
        }

        var validValue: Field.Point

        let s = solution[row][column]
        if s == 0 {
            validValue = .empty
        } else {
            let color = colors[s - 1]
            if layerColorId != nil {
                if layerColorId == color.id {
                    validValue = .init(value: .color(color))
                } else {
                    validValue = .empty
                }
            } else {
                validValue = .init(value: .color(color))
            }
        }

        if validValue == newValue {
            field.points[row][column] = newValue

            fieldView.horizontalDefsCell.focusedIndex = row
            fieldView.verticalDefsCell.focusedIndex = column
            solutionView.focusedCell = (row: row, column: column)

            if let layerId = layerColorId {
                layers[layerId] = field
            }
            strikeEmptyCellsIfResolved(row: row)
            strikeEmptyCellsIfResolved(column: column)

            applyState()

            delegate?.resolvingViewController(
                self,
                didChangeState: sourceField ?? field,
                layers: layers,
                currentLayer: layerColorId,
                solution: solution,
                colors: colors,
                url: url
            )

            return false
        } else {
            solutionView.showError(row: row, column: column)
            return true
        }
    }
}

extension ResolvingViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
}
