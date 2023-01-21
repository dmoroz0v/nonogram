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
        colors: [Field.Color]
    )

    func resolvingViewControllerDidTapExit(_: ResolvingViewController)
}

class ResolvingViewController: UIViewController {

    enum UpdateAction {
        case selectLayer(penColor: Field.Color)
        case selectPen(pen: Pen)
        case closeAndSelectPen(pen: Pen)
    }

    weak var delegate: ResolvingViewControllerDelegate?

    // views
    private let scrollView = UIScrollView()
    private let contentView = CellView()
    private let menuView = MenuView()
    private let horizontalDefsCell = NumbersView()
    private let verticalDefsCell = NumbersView()
    private let solutionView = SolutionView()

    private let solution: [[Int]]
    private let colors: [Field.Color]
    private var field: Field!
    private var sourceField: Field!
    private var layers: [String: Field] = [:]
    private var layerColorId: String?
    private var pen: Pen = .empty {
        didSet {
            menuView.pen = pen
        }
    }

    init(
        horizontalDefs: [[Field.Definition]],
        verticalDefs: [[Field.Definition]],
        solution: [[Int]],
        colors: [Field.Color]
    ) {
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
        field: Field,
        layers: [String: Field],
        currentLayer: String?,
        solution: [[Int]],
        colors: [Field.Color]
    ) {
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
        scrollView.maximumZoomScale = 5
        scrollView.delegate = self
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.clipsToBounds = true
        scrollView.addSubview(contentView)
        scrollView.contentInset = .init(top: 60, left: 40, bottom: 60, right: 40)

        let field: Field! = (sourceField ?? field)

        let cellAspectSize: CGFloat = 24
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
        contentView.contentView.addSubview(leftTopCell)

        horizontalDefsCell.translatesAutoresizingMaskIntoConstraints = false
        horizontalDefsCell.delegate = self
        horizontalDefsCell.cellAspectSize = cellAspectSize
        horizontalDefsCell.pickColorHandler = { [weak self] color in
            self?.update(with: .selectPen(pen: .color(color)))
        }
        horizontalDefsCell.defs = field.horizintals
        horizontalDefsCell.offset = maxHorizintalDefs
        horizontalDefsCell.axis = .horizontal
        contentView.contentView.addSubview(horizontalDefsCell)

        verticalDefsCell.translatesAutoresizingMaskIntoConstraints = false
        verticalDefsCell.delegate = self
        verticalDefsCell.cellAspectSize = cellAspectSize
        verticalDefsCell.pickColorHandler = { [weak self] color in
            self?.update(with: .selectPen(pen: .color(color)))
        }
        verticalDefsCell.defs = field.verticals
        verticalDefsCell.offset = maxVerticalDefs
        verticalDefsCell.axis = .vertical
        contentView.contentView.addSubview(verticalDefsCell)

        solutionView.translatesAutoresizingMaskIntoConstraints = false
        solutionView.size = field.size
        solutionView.cellAspectSize = cellAspectSize
        solutionView.delegate = self
        solutionView.dataSource = self
        contentView.contentView.addSubview(solutionView)

        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuView.colors = field.colors
        menuView.delegate = self
        view.addSubview(menuView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(
                equalToConstant: CGFloat(maxHorizintalDefs + field.size.columns) * cellAspectSize),
            contentView.heightAnchor.constraint(
                equalToConstant: CGFloat(maxVerticalDefs + field.size.rows) * cellAspectSize),

            leftTopCell.topAnchor.constraint(equalTo: contentView.contentView.topAnchor),
            leftTopCell.leadingAnchor.constraint(equalTo: contentView.contentView.leadingAnchor),
            leftTopCell.widthAnchor.constraint(equalToConstant: CGFloat(maxHorizintalDefs) * cellAspectSize),
            leftTopCell.heightAnchor.constraint(equalToConstant: CGFloat(maxVerticalDefs) * cellAspectSize),

            horizontalDefsCell.topAnchor.constraint(equalTo: leftTopCell.bottomAnchor),
            horizontalDefsCell.leadingAnchor.constraint(equalTo: contentView.contentView.leadingAnchor),
            horizontalDefsCell.bottomAnchor.constraint(equalTo: contentView.contentView.bottomAnchor),
            horizontalDefsCell.widthAnchor.constraint(equalToConstant: CGFloat(maxHorizintalDefs) * cellAspectSize),

            verticalDefsCell.topAnchor.constraint(equalTo: contentView.contentView.topAnchor),
            verticalDefsCell.leadingAnchor.constraint(equalTo: leftTopCell.trailingAnchor),
            verticalDefsCell.trailingAnchor.constraint(equalTo: contentView.contentView.trailingAnchor),
            verticalDefsCell.heightAnchor.constraint(equalToConstant: CGFloat(maxVerticalDefs) * cellAspectSize),

            solutionView.topAnchor.constraint(equalTo: verticalDefsCell.bottomAnchor),
            solutionView.leadingAnchor.constraint(equalTo: horizontalDefsCell.trailingAnchor),
            solutionView.trailingAnchor.constraint(equalTo: contentView.contentView.trailingAnchor),
            solutionView.bottomAnchor.constraint(equalTo: contentView.contentView.bottomAnchor),

            menuView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            menuView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        applyState()
    }

    func checkRownAndColumn(row: Int, column: Int) {
        var rowIsResolved = true
        for columnIndex in 0..<field.size.columns {
            if field.points[row][columnIndex] == .undefined && solution[row][columnIndex] > 0 {
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

        var columnIsResolver = true
        for rowIndex in 0..<field.size.rows {
            if field.points[rowIndex][column] == .undefined && solution[rowIndex][column] > 0 {
                columnIsResolver = false
            }
        }
        if columnIsResolver {
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
        case .closeAndSelectPen(let pen):
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
            colors: colors
        )
    }

    func applyState() {
        solutionView.setNeedsDisplay()
        horizontalDefsCell.defs = field.horizintals
        horizontalDefsCell.setNeedsDisplay()
        verticalDefsCell.defs = field.verticals
        verticalDefsCell.setNeedsDisplay()

        if layerColorId == nil {
            menuView.showCommon()
        } else {
            menuView.showLayer(color: field.colors.first(where: { $0.id == layerColorId })!)
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

extension ResolvingViewController: MenuViewDelegate {
    func menuViewDidTapExit(_: MenuView) {
        delegate?.resolvingViewControllerDidTapExit(self)
    }

    func menuViewDidSelctColorForCurrentLayer(_: MenuView, color: Field.Color) {
        pen = .layer(color)
    }

    func menuViewDidCloseLayer(_ mv: MenuView) {
        if case .layer(let c) = pen {
            update(with: .closeAndSelectPen(pen: .color(c)))
        } else {
            update(with: .closeAndSelectPen(pen: .empty))
        }
    }

    func menuViewPresentingViewController(_: MenuView) -> UIViewController {
        return self
    }

    func menuView(_: MenuView, didSelectPen pen: Pen) {
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
        horizontalDefsCell.focusedIndex = row
        verticalDefsCell.focusedIndex = column
        solutionView.focusedCell = (row: row, column: column)
    }

    func solutionView(_ solutionView: SolutionView, didTapColumn column: Int, row: Int) {
        if field.points[row][column] != .undefined {
            return
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

            horizontalDefsCell.focusedIndex = row
            verticalDefsCell.focusedIndex = column
            solutionView.focusedCell = (row: row, column: column)

            if let layerId = layerColorId {
                layers[layerId] = field
            } else {
                checkRownAndColumn(row: row, column: column)
            }

            applyState()

            delegate?.resolvingViewController(
                self,
                didChangeState: sourceField ?? field,
                layers: layers,
                currentLayer: layerColorId,
                solution: solution,
                colors: colors
            )
        } else {
            // show error
        }
    }
}

extension ResolvingViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
}
