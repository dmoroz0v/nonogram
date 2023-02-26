//
//  ResolvingViewController.swift
//  nonogram
//
//  Created by Denis S. Morozov on 12.01.2023.
//

import Foundation
import UIKit

enum Pen: Equatable {
    case empty
    case color(Field.Color)
}

protocol ResolvingViewControllerDelegate: AnyObject {
    func resolvingViewController(
        _: ResolvingViewController,
        didChangeState: Field,
        layers: [String: Field],
        selectedLayerColor: Field.Color?,
        solution: [[Int]],
        url: URL,
        thumbnailUrl: URL,
        title: String,
        showsErrors: Bool
    )

    func resolvingViewControllerDidTapExit(_: ResolvingViewController)
}

final class ResolvingViewController: UIViewController {

    enum SwitchLayerAction {
        case selectLayer(penColor: Field.Color)
        case closeLayer
    }

    weak var delegate: ResolvingViewControllerDelegate?

    // views
    private let scrollView = UIScrollView()
    private let controlsPanelVC = ControlsPanelViewController()
    private var fieldView: FieldView!

    private var controlsPanelViewHotizontal: NSLayoutConstraint?
    private var controlsPanelViewVertical: NSLayoutConstraint?

    private let url: URL
    private let thumbnailUrl: URL
    private let crosswordTitle: String
    private let solution: [[Int]]
    private var fullField: Field
    private var layers: [String: Field] = [:]
    private var field: Field {
        if let selectedLayerColor {
            return layers[selectedLayerColor.id]!
        } else {
            return fullField
        }
    }
    private var showsErrors: Bool = false
    private var selectedLayerColor: Field.Color? {
        didSet {
            controlsPanelVC.style = selectedLayerColor != nil ? .layer : .default
        }
    }
    private var lastColoredPen: Pen?
    private var pen: Pen = .empty {
        didSet {
            if oldValue != .empty {
                lastColoredPen = oldValue
            }
            controlsPanelVC.pen = pen
        }
    }

    init(
        url: URL,
        thumbnailUrl: URL,
        title: String,
        horizontalLinesHunks: [[Field.LineHunk]],
        verticalLinesHunks: [[Field.LineHunk]],
        solution: [[Int]],
        colors: [Field.Color]
    ) {
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.crosswordTitle = title
        fullField = Field(
            values: Array<[Field.Value?]>(
                repeating: Array<Field.Value?>(repeating: nil, count: verticalLinesHunks.count),
                count: horizontalLinesHunks.count
            ),
            horizontalLinesHunks: horizontalLinesHunks,
            verticalLinesHunks: verticalLinesHunks,
            colors: colors
        )
        self.solution = solution
        super.init(nibName: nil, bundle: nil)
    }

    init(
        url: URL,
        thumbnailUrl: URL,
        title: String,
        fullField: Field,
        layers: [String: Field],
        selectedLayerColor: Field.Color?,
        solution: [[Int]],
        showsErrors: Bool
    ) {
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.crosswordTitle = title
        self.fullField = fullField
        self.layers = layers
        self.selectedLayerColor = selectedLayerColor
        self.solution = solution
        self.showsErrors = showsErrors
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

        scrollView.contentInset = .init(top: 60, left: 40, bottom: 60, right: 40)

        fieldView = FieldView(
            frame: .zero,
            solutionSize: fullField.size,
            verticalMaxHunks: fullField.verticalLinesHunks.map({ $0.count }).max()!,
            horizontalMaxHunks: fullField.horizontalLinesHunks.map({ $0.count }).max()!
        )
        fieldView.translatesAutoresizingMaskIntoConstraints = false

        fieldView.horizontalLinesHunksCell.delegate = self
        fieldView.horizontalLinesHunksCell.pickColorHandler = { [weak self] color in
            self?.pen = .color(color)
        }

        fieldView.verticalLinesHunksCell.delegate = self
        fieldView.verticalLinesHunksCell.pickColorHandler = { [weak self] color in
            self?.pen = .color(color)
        }

        fieldView.solutionView.delegate = self
        fieldView.solutionView.dataSource = self

        scrollView.addSubview(fieldView)

        controlsPanelVC.view.translatesAutoresizingMaskIntoConstraints = false
        controlsPanelVC.delegate = self
        addChild(controlsPanelVC)
        view.addSubview(controlsPanelVC.view)
        controlsPanelVC.didMove(toParent: self)

        let controlsPanelViewPanGR = UIPanGestureRecognizer(
            target: self,
            action: #selector(controlsPanelViewPan(_:))
        )
        controlsPanelVC.view.addGestureRecognizer(controlsPanelViewPanGR)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            fieldView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            fieldView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            fieldView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            fieldView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            {
                controlsPanelViewHotizontal = controlsPanelVC.view.leadingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.leadingAnchor)
                return controlsPanelViewHotizontal!
            }(),
            {
                controlsPanelViewVertical = controlsPanelVC.view.centerYAnchor.constraint(
                    equalTo: view.centerYAnchor)
                return controlsPanelViewVertical!
            }(),
        ])

        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = self
        view.addInteraction(pencilInteraction)

        controlsPanelVC.pen = pen
        controlsPanelVC.style = selectedLayerColor != nil ? .layer : .default
        fieldView.horizontalLinesHunksCell.linesHunks = field.horizontalLinesHunks
        fieldView.verticalLinesHunksCell.linesHunks = field.verticalLinesHunks

        updateUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if controlsPanelViewHotizontal!.constant > view.frame.width - controlsPanelVC.view.frame.width {
            controlsPanelViewHotizontal!.constant = view.frame.width - controlsPanelVC.view.frame.width
        }
        if controlsPanelViewHotizontal!.constant < 0 {
            controlsPanelViewHotizontal!.constant = 0
        }
        if controlsPanelViewVertical!.constant > view.frame.height/2 - controlsPanelVC.view.frame.height/2 {
            controlsPanelViewVertical!.constant = view.frame.height/2 - controlsPanelVC.view.frame.height/2
        }
        if controlsPanelViewVertical!.constant < -view.frame.height/2 + controlsPanelVC.view.frame.height/2 {
            controlsPanelViewVertical!.constant = -view.frame.height/2 + controlsPanelVC.view.frame.height/2
        }
    }

    private func strikeEmptyCellsIfResolved(row: Int) -> Bool {
        var rowIsResolved = true
        for columnIndex in 0..<field.size.columns {
            let validValue = validValue(row: row, column: columnIndex)
            let value = field.values[row][columnIndex]
            switch validValue {
            case .empty:
                if value != nil && value != .empty {
                    rowIsResolved = false
                }
            case .color:
                if value != validValue {
                    rowIsResolved = false
                }
            }
        }
        if rowIsResolved {
            for columnIndex in 0..<field.size.columns {
                if field.values[row][columnIndex] == nil {
                    field.values[row][columnIndex] = .empty
                }
            }
        }
        return rowIsResolved
    }

    private func strikeEmptyCellsIfResolved(column: Int) -> Bool {
        var columnIsResolved = true
        for rowIndex in 0..<field.size.rows {
            let validValue = validValue(row: rowIndex, column: column)
            let value = field.values[rowIndex][column]
            switch validValue {
            case .empty:
                if value != nil && value != .empty {
                    columnIsResolved = false
                }
            case .color:
                if value != validValue {
                    columnIsResolved = false
                }
            }
        }
        if columnIsResolved {
            for rowIndex in 0..<field.size.rows {
                if field.values[rowIndex][column] == nil {
                    field.values[rowIndex][column] = .empty
                }
            }
        }
        return columnIsResolved
    }

    private func switchLayer(with action: SwitchLayerAction) {
        switch action {
        case .selectLayer(let penColor):
            self.pen = .color(penColor)

            var layerField: Field

            if let field = layers[penColor.id] {
                layerField = field
            } else {
                layerField = Field(
                    values: field.values.map({ row in
                        var row = row
                        for (rowIndex, value) in row.enumerated() {
                            if case .color(let c) = value, c.id != penColor.id {
                                row[rowIndex] = .empty
                            }
                        }
                        return row
                    }),
                    horizontalLinesHunks: field.horizontalLinesHunks.map({ lineHunks in
                        return lineHunks.filter { hunk in
                            hunk.color.id == penColor.id
                        }
                    }),
                    verticalLinesHunks: field.verticalLinesHunks.map({ lineHunks in
                        return lineHunks.filter { hunk in
                            hunk.color.id == penColor.id
                        }
                    }),
                    colors: field.colors.filter({
                        $0.id == penColor.id
                    })
                )
                layers[penColor.id] = layerField
            }

            for (rowIndex, row) in field.values.enumerated() {
                for (columnIndex, value) in row.enumerated() {
                    if case .color(let c) = value {
                        if c.id == penColor.id {
                            layerField.values[rowIndex][columnIndex] = value
                        } else {
                            layerField.values[rowIndex][columnIndex] = .empty
                        }
                    }
                    if value == .empty {
                        layerField.values[rowIndex][columnIndex] = value
                    }
                }
            }

            selectedLayerColor = penColor
        case .closeLayer:
            for (rowIndex, row) in field.values.enumerated() {
                for (columnIndex, value) in row.enumerated() {
                    if case .color(let c) = value, c == selectedLayerColor {
                        fullField.values[rowIndex][columnIndex] = value
                    }
                }
            }
            selectedLayerColor = nil
        }

        fieldView.horizontalLinesHunksCell.linesHunks = field.horizontalLinesHunks
        fieldView.verticalLinesHunksCell.linesHunks = field.verticalLinesHunks

        updateUI()

        delegate?.resolvingViewController(
            self,
            didChangeState: fullField,
            layers: layers,
            selectedLayerColor: selectedLayerColor,
            solution: solution,
            url: url,
            thumbnailUrl: thumbnailUrl,
            title: crosswordTitle,
            showsErrors: showsErrors
        )
    }

    private func updateUI() {

        var isResolved = true
        for rowIndex in 0..<field.size.rows {
            isResolved = strikeEmptyCellsIfResolved(row: rowIndex) && isResolved
        }
        for columnIndex in 0..<field.size.columns {
            isResolved = strikeEmptyCellsIfResolved(column: columnIndex) && isResolved
        }

        let hasErrors = checkForError()

        if !hasErrors && isResolved && selectedLayerColor == nil {
            showResolvedAlert()
        }

        fieldView.solutionView.setNeedsDisplay()
        fieldView.horizontalLinesHunksCell.setNeedsDisplay()
        fieldView.verticalLinesHunksCell.setNeedsDisplay()
    }

    private func checkForError() -> Bool {
        var errorsCount = 0
        let minErrorsCount = 5
        for rowIndex in 0..<field.size.rows {
            for columntIndex in 0..<field.size.columns {
                let validValue: Field.Value = validValue(row: rowIndex, column: columntIndex)
                let value = field.values[rowIndex][columntIndex]
                if value != nil && validValue != value {
                    errorsCount += 1
                    if errorsCount == minErrorsCount {
                        break
                    }
                }
            }
            if errorsCount == minErrorsCount {
                break
            }
        }
        let showsErrors = (errorsCount >= minErrorsCount)
        if !showsErrors {
            if errorsCount == 0 {
                self.showsErrors = false
            }
        } else {
            self.showsErrors = true
        }
        return errorsCount > 0
    }

    private func validValue(row: Int, column: Int) -> Field.Value {
        let value = solution[row][column]
        if value == 0 {
            return .empty
        } else {
            let color = fullField.colors[value - 1]
            if let selectedLayerColor {
                if selectedLayerColor.id == color.id {
                    return .color(color)
                } else {
                    return .empty
                }
            } else {
                return .color(color)
            }
        }
    }

    private func showResolvedAlert() {
        let alert = UIAlertController(title: "Решено!", message: "", preferredStyle: .alert)
        alert.addAction(.init(title: "Хорошо!", style: .default))
        present(alert, animated: true)
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

}

extension ResolvingViewController: UIPencilInteractionDelegate {
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        if let selectedLayerColor {
            switch pen {
            case .empty:
                pen = .color(selectedLayerColor)
            case .color:
                pen = .empty
            }
        } else {
            switch pen {
            case .empty:
                pen = lastColoredPen ?? .color(fullField.colors.first!)
            case .color:
                pen = .empty
            }
        }

        let penSwhitchedView: UIView
        switch pen {
        case .empty:
            let emptyView = ControlsPanelView.EmptyView(dotRadius: 4)
            penSwhitchedView = emptyView
        case .color(let c):
            let coloredView = UIView()
            coloredView.backgroundColor = c.c
            penSwhitchedView = coloredView
        }

        penSwhitchedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(penSwhitchedView)

        penSwhitchedView.layer.shadowOpacity = 0.2
        penSwhitchedView.layer.shadowColor = UIColor.black.cgColor
        penSwhitchedView.layer.shadowRadius = 12
        penSwhitchedView.layer.cornerRadius = 12

        NSLayoutConstraint.activate([
            penSwhitchedView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            penSwhitchedView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            penSwhitchedView.widthAnchor.constraint(equalToConstant: 64),
            penSwhitchedView.heightAnchor.constraint(equalToConstant: 64),
        ])

        UIView.animate(withDuration: 0.25, delay: 0.5, animations: {
            penSwhitchedView.alpha = 0
        }, completion: { _ in
            penSwhitchedView.removeFromSuperview()
        })
    }
}

extension ResolvingViewController: LinesHunksViewDelegate {

    func linesHunksView(_ linesHunksView: LinesHunksView, strikedHunksForIndex hunksIndex: Int) -> [Int] {
        var result: [Int] = []
        let line = lineForIndex(hunksIndex, for: linesHunksView)

        // >> проходимся от начала линии до конца и пытаемся вычеркнуть цифры слева или сверху
        result += strikedHunks(
            line: line,
            range: Array(0..<line.count),
            hunkStartIndex: 0,
            increment: 1,
            hunksIndex: hunksIndex,
            linesHunksView: linesHunksView)
        // <<

        // >> проходимся от конца линии до начала и пытаемся вычеркнуть цифры справа или снизу
        result += strikedHunks(
            line: line,
            range: (0..<line.count).reversed(),
            hunkStartIndex: linesHunksView.linesHunks[hunksIndex].count - 1,
            increment: -1,
            hunksIndex: hunksIndex,
            linesHunksView: linesHunksView)
        // <<

        return result
    }

    private func lineForIndex(_ index: Int, for linesHunksView: LinesHunksView) -> [Field.Value?] {
        if linesHunksView.axis == .horizontal {
            let row = index
            return field.values[row]
        } else {
            let column = index
            var result: [Field.Value?] = []
            for rowIndex in 0..<field.size.rows {
                result.append(field.values[rowIndex][column])
            }
            return result
        }
    }

    private func strikedHunks(
        line: [Field.Value?],
        range: [Int],
        hunkStartIndex: Int,
        increment: Int,
        hunksIndex: Int,
        linesHunksView: LinesHunksView
    ) -> [Int] {
        var result: [Int] = []
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
                    result.append(hunkIndex)
                    n = 0
                    hunkIndex += increment
                }
            }
        }
        return result
    }
}

extension ResolvingViewController: ControlsPanelViewControllerDelegate {

    func controlsPanelViewControllerColors(_: ControlsPanelViewController) -> [Field.Color] {
        return field.colors
    }

    func controlsPanelViewControllerDidTapExit(_: ControlsPanelViewController) {
        delegate?.resolvingViewControllerDidTapExit(self)
    }

    func controlsPanelViewController(_: ControlsPanelViewController, didSelectLayerColor color: Field.Color) {
        switchLayer(with: .selectLayer(penColor: color))
    }

    func controlsPanelViewControllerDidTapCloseLayer(_: ControlsPanelViewController) {
        switchLayer(with: .closeLayer)
    }

    func controlsPanelViewController(_: ControlsPanelViewController, didSelectPen pen: Pen) {
        self.pen = pen
    }
}

extension ResolvingViewController: SolutionViewDelegate, SolutionViewDataSource {
    func solutionView(_ solutionView: SolutionView, valueForColumn column: Int, row: Int) -> Field.Value? {
        return field.values[row][column]
    }

    func solutionView(_: SolutionView, validValueForColumn column: Int, row: Int) -> Field.Value {
        return validValue(row: row, column: column)
    }

    func solutionViewNeedShowsErrors(_: SolutionView) -> Bool {
        return showsErrors
    }

    func solutionView(_ solutionView: SolutionView, didLongTapColumn column: Int, row: Int) {
        fieldView.horizontalLinesHunksCell.focusedIndex = row
        fieldView.verticalLinesHunksCell.focusedIndex = column
        solutionView.focusedCell = (row: row, column: column)
    }

    func solutionView(_ solutionView: SolutionView, didTouchColumn column: Int, row: Int) -> Bool {
        var newValue: Field.Value
        switch pen {
        case .empty:
            newValue = .empty
        case .color(let c):
            newValue = .color(c)
        }

        if field.values[row][column] != newValue {
            field.values[row][column] = newValue
        } else {
            field.values[row][column] = nil
        }

        fieldView.horizontalLinesHunksCell.focusedIndex = row
        fieldView.verticalLinesHunksCell.focusedIndex = column
        solutionView.focusedCell = (row: row, column: column)

        if let selectedLayerColor {
            layers[selectedLayerColor.id] = field
        }

        updateUI()

        delegate?.resolvingViewController(
            self,
            didChangeState: fullField,
            layers: layers,
            selectedLayerColor: selectedLayerColor,
            solution: solution,
            url: url,
            thumbnailUrl: thumbnailUrl,
            title: crosswordTitle,
            showsErrors: showsErrors
        )

        return false
    }
}

extension ResolvingViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return fieldView
    }
}
