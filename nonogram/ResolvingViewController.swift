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

class ResolvingViewController: UIViewController, UIScrollViewDelegate, MenuViewDelegate, SolutionViewDelegate, SolutionViewDataSource, NumbersViewDelegate {

    enum UpdateAction {
        case selectLayer(penColor: Field.Color)
        case selectPen(pen: Pen)
        case closeAndSelectPen(pen: Pen)
    }

    func numbersView(_ numbersView: NumbersView, line: Int) -> [Field.Point] {
        if numbersView.axis == .horizontal {
            return field.points[line]
        } else {
            var result: [Field.Point] = []
            for i in 0..<field.points.count {
                result.append(field.points[i][line])
            }
            return result
        }
    }

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

    func solutionView(_ solutionView: SolutionView, pointForI i: Int, J j: Int) -> Field.Point {
        return field.points[j][i]
    }

    func solutionView(_ solutionView: SolutionView, didLongTapI i: Int, J j: Int) {
        let row = j
        let column = i

        horizontalsCell.focusedLine = row
        verticalsCell.focusedLine = column
    }

    func solutionView(_ solutionView: SolutionView, didTapI i: Int, J j: Int) {
        let row = j
        let column = i

        horizontalsCell.focusedLine = row
        verticalsCell.focusedLine = column

        var newValue: Field.Point
        switch pen {
        case .empty:
            newValue = .init(value: .empty)
        case .color(let c):
            newValue = .init(value: .color(c))
        case .layer(let c):
            newValue = .init(value: .color(c))
        }
        if newValue == field.points[row][column] {
            field.points[row][column] = .init(value: nil)
        } else {
            field.points[row][column] = newValue

            let s = solution[row][column]
            if s == 0 && newValue != .init(value: .empty) {
                field.points[row][column] = .init(value: nil)
            }
            if s > 0 {
                let c = colors[s - 1]
                if layerColorId == nil {
                    if newValue != .init(value: .color(c)) {
                        field.points[row][column] = .init(value: nil)
                    }
                    if newValue == .init(value: .empty) {
                        field.points[row][column] = .init(value: nil)
                    }
                } else {
                    if layerColorId == c.id && newValue == .init(value: .empty) {
                        field.points[row][column] = .init(value: nil)
                    }
                }
            }
        }

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
    }

    func checkRownAndColumn(row: Int, column: Int) {
        var rowIsResolved = true
        solution[row].enumerated().forEach { column, value in
            if field.points[row][column] == .init(value: nil) && value > 0 {
                rowIsResolved = false
            }
        }
        if rowIsResolved {
            for columnIndex in 0..<field.points[row].count {
                if field.points[row][columnIndex] == .init(value: nil) {
                    field.points[row][columnIndex] = .init(value: .empty)
                }
            }
        }

        var columnIsResolver = true
        for rowIndex in 0..<solution.count {
            if field.points[rowIndex][column] == .init(value: nil) && solution[rowIndex][column] > 0 {
                columnIsResolver = false
            }
        }
        if columnIsResolver {
            for rowIndex in 0..<solution.count {
                if field.points[rowIndex][column] == .init(value: nil) {
                    field.points[rowIndex][column] = .init(value: .empty)
                }
            }
        }
    }

    func menuViewPresentingViewController(_: MenuView) -> UIViewController {
        return self
    }

    func update(with action: UpdateAction) {

        switch action {
        case .selectLayer(let penColor):
            self.pen = .layer(penColor)
            sourceField = field
            if layers[penColor.id] == nil {
                layers[penColor.id] = Field(
                    points: field.points.map({ line in
                        var line = line
                        for (i, point) in line.enumerated() {
                            if case .color(let c) = point.value, c.id != penColor.id {
                                line[i] = .init(value: .empty)
                            }
                        }
                        return line
                    }),
                    horizintals: sourceField.horizintals.map({ element in
                        return element.filter { def in
                            def.color.id == penColor.id
                        }
                    }),
                    verticals: sourceField.verticals.map({ element in
                        return element.filter { def in
                            def.color.id == penColor.id
                        }
                    })
                )
            }

            field = layers[penColor.id]

            for (i, line) in sourceField.points.enumerated() {
                for (j, p) in line.enumerated() {
                    if case .color(let c) = p.value {
                        if c.id == penColor.id {
                            field.points[i][j] = p
                        } else {
                            field.points[i][j] = .init(value: .empty)
                        }
                    }
                    if case .empty = p.value {
                        field.points[i][j] = p
                    }
                }
            }

            layerColorId = penColor.id
        case .closeAndSelectPen(let pen):
            self.pen = pen

            layers[layerColorId!] = field
            field = sourceField
            sourceField = nil

            for (i, line) in layers[layerColorId!]!.points.enumerated() {
                for (j, p) in line.enumerated() {
                    if case .color(let c) = p.value, c.id == layerColorId {
                        field.points[i][j] = p
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
        horizontalsCell.numbers = field.horizintals
        horizontalsCell.setNeedsDisplay()
        verticalsCell.numbers = field.verticals
        verticalsCell.setNeedsDisplay()

        if layerColorId == nil {
            menuView.showCommon()
        } else {
            menuView.showLayer(color: field.colors.first(where: { $0.id == layerColorId })!)
        }
    }

    func menuView(_: MenuView, didSelectPen pen: Pen) {
        if case .layer(let penColor) = pen {
            update(with: .selectLayer(penColor: penColor))
        } else {
            update(with: .selectPen(pen: pen))
        }
    }

    weak var delegate: ResolvingViewControllerDelegate?

    // views
    private let scrollView = UIScrollView()
    private let contentView = CellView()
    private let menuView = MenuView()
    private let horizontalsCell = NumbersView()
    private let verticalsCell = NumbersView()
    private let solutionView = SolutionView()

    // init state
    private let horizontalDefs: [[Field.Definition]]
    private let verticalDefs: [[Field.Definition]]
    private let solution: [[Int]]
    private let colors: [Field.Color]

    // current state
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
        self.horizontalDefs = horizontalDefs
        self.verticalDefs = verticalDefs
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
        self.horizontalDefs = field.horizintals
        self.verticalDefs = field.verticals
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

        if field == nil {
            field = Field(
                points: Array<[Field.Point]>(
                    repeating: Array<Field.Point>(repeating: .init(value: nil), count: verticalDefs.count),
                    count: horizontalDefs.count
                ),
                horizintals: horizontalDefs,
                verticals: verticalDefs)
        }

        let field: Field! = (sourceField ?? field)

        let hMax = field.horizintals.reduce(0) { prev, current in
            if current.count > prev {
                return current.count
            }
            return prev
        }

        let vMax = field.verticals.reduce(0) { prev, current in
            if current.count > prev {
                return current.count
            }
            return prev
        }

        let cellAspectSize: CGFloat = 24

        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalToConstant: CGFloat(hMax + field.size.columns) * cellAspectSize),
            contentView.heightAnchor.constraint(equalToConstant: CGFloat(vMax + field.size.rows) * cellAspectSize),
        ])

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])

        let leftTopCell = CellView()
        leftTopCell.translatesAutoresizingMaskIntoConstraints = false
        contentView.contentView.addSubview(leftTopCell)
        NSLayoutConstraint.activate([
            leftTopCell.topAnchor.constraint(equalTo: contentView.topAnchor),
            leftTopCell.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            leftTopCell.widthAnchor.constraint(equalToConstant: CGFloat(hMax) * cellAspectSize),
            leftTopCell.heightAnchor.constraint(equalToConstant: CGFloat(vMax) * cellAspectSize),
        ])

        horizontalsCell.delegate = self
        horizontalsCell.cellAspectSize = cellAspectSize
        horizontalsCell.pickColorHandler = { [weak self] color in
            self?.update(with: .selectPen(pen: .color(color)))
        }
        horizontalsCell.numbers = field.horizintals
        horizontalsCell.offset = field.horizintals.reduce(0) { partialResult, line in
            if line.count > partialResult {
                return line.count
            }
            return partialResult
        }
        horizontalsCell.axis = .horizontal
        horizontalsCell.translatesAutoresizingMaskIntoConstraints = false
        contentView.contentView.addSubview(horizontalsCell)
        NSLayoutConstraint.activate([
            horizontalsCell.topAnchor.constraint(equalTo: contentView.contentView.topAnchor, constant: CGFloat(vMax) * cellAspectSize),
            horizontalsCell.leadingAnchor.constraint(equalTo: contentView.contentView.leadingAnchor),
            horizontalsCell.bottomAnchor.constraint(equalTo: contentView.contentView.bottomAnchor),
            horizontalsCell.widthAnchor.constraint(equalToConstant: CGFloat(hMax) * cellAspectSize),
        ])

        verticalsCell.delegate = self
        verticalsCell.cellAspectSize = cellAspectSize
        verticalsCell.pickColorHandler = { [weak self] color in
            self?.update(with: .selectPen(pen: .color(color)))
        }
        verticalsCell.numbers = field.verticals
        verticalsCell.offset = field.verticals.reduce(0) { partialResult, line in
            if line.count > partialResult {
                return line.count
            }
            return partialResult
        }
        verticalsCell.axis = .vertical
        verticalsCell.translatesAutoresizingMaskIntoConstraints = false
        contentView.contentView.addSubview(verticalsCell)
        NSLayoutConstraint.activate([
            verticalsCell.topAnchor.constraint(equalTo: contentView.contentView.topAnchor),
            verticalsCell.leadingAnchor.constraint(equalTo: contentView.contentView.leadingAnchor, constant: CGFloat(hMax) * cellAspectSize),
            verticalsCell.trailingAnchor.constraint(equalTo: contentView.contentView.trailingAnchor),
            verticalsCell.heightAnchor.constraint(equalToConstant: CGFloat(vMax) * cellAspectSize),
        ])

        solutionView.translatesAutoresizingMaskIntoConstraints = false
        solutionView.size = field.size
        solutionView.cellAspectSize = cellAspectSize
        solutionView.delegate = self
        solutionView.dataSource = self
        contentView.contentView.addSubview(solutionView)

        NSLayoutConstraint.activate([
            solutionView.topAnchor.constraint(equalTo: verticalsCell.bottomAnchor),
            solutionView.leadingAnchor.constraint(equalTo: horizontalsCell.trailingAnchor),
            solutionView.trailingAnchor.constraint(equalTo: contentView.contentView.trailingAnchor),
            solutionView.bottomAnchor.constraint(equalTo: contentView.contentView.bottomAnchor),
        ])

        menuView.colors = field.colors
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuView.delegate = self
        view.addSubview(menuView)

        NSLayoutConstraint.activate([
            menuView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            menuView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        applyState()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }

}
