//
//  ViewController.swift
//  nonogram
//
//  Created by Denis S. Morozov on 12.01.2023.
//

import UIKit

struct Field {
    struct Color {
        var c: UIColor
        var id: String {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            c.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return "\(Int(red*255))-\(Int(green*255))-\(Int(blue*255))-\(Int(alpha*255))"
        }
    }

    struct Point {
        enum Value {
            case color(Color)
            case empty
        }
        var value: Value?
    }

    struct Definition {
        var color: Color
        var n: Int
    }

    var points: [[Point]]

    var horizintals: [[Definition]]
    var verticals: [[Definition]]
    var size: (w: Int, h: Int) {
        return (w: points[0].count, h: points.count)
    }

    var colors: [Color] {
        var result: [String: Color] = [:]
        for def in (horizintals.flatMap({ $0 }) + verticals.flatMap({ $0 })) {
            result[def.color.id] = def.color
        }
        return Array(result.values)
    }
}

class CellView: UIView {

    let contentView = UIView()

    var borderMask: UIEdgeInsets = .init(top: 1, left: 1, bottom: 1, right: 1) {
        didSet {
            updateBorders()
        }
    }

    private var borderViews: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(contentView)

        updateBorders()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.frame = bounds

        borderViews[0].frame = CGRect(x: 0, y: 0, width: 1/UIScreen.main.scale, height: bounds.height)
        borderViews[1].frame = CGRect(
            x: bounds.width - 1/UIScreen.main.scale,
            y: 0,
            width: 1/UIScreen.main.scale,
            height: bounds.height)

        borderViews[2].frame = CGRect(x: 0, y: 0, width: bounds.width, height: 1/UIScreen.main.scale)
        borderViews[3].frame = CGRect(
            x: 0,
            y: bounds.height - 1/UIScreen.main.scale,
            width: bounds.width,
            height: 1/UIScreen.main.scale)
    }

    private func updateBorders() {
        borderViews.forEach {
            $0.removeFromSuperview()
        }

        let leftBorder = UIView()
        leftBorder.translatesAutoresizingMaskIntoConstraints = false
        leftBorder.backgroundColor = .black
        leftBorder.isHidden = borderMask.left == 0

        let rightBorder = UIView()
        rightBorder.translatesAutoresizingMaskIntoConstraints = false
        rightBorder.backgroundColor = .black
        rightBorder.isHidden = borderMask.right == 0

        let topBorder = UIView()
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        topBorder.backgroundColor = .black
        topBorder.isHidden = borderMask.top == 0

        let bottomBorder = UIView()
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        bottomBorder.backgroundColor = .black
        bottomBorder.isHidden = borderMask.bottom == 0

        borderViews = [
            leftBorder,
            rightBorder,
            topBorder,
            bottomBorder,
        ]

        addSubview(leftBorder)
        addSubview(rightBorder)
        addSubview(topBorder)
        addSubview(bottomBorder)
    }

}

protocol FiveXFiveDelegate: AnyObject {
    func fiveXFive(_: FiveXFive, didTapI: Int, J: Int)
    func fiveXFive(_: FiveXFive, pointForI: Int, J: Int) -> Field.Point
}

class FiveXFive: CellView {

    weak var delegate: FiveXFiveDelegate?

    private var horizontals: [UIView] = []
    private var verticals: [UIView] = []

    var i: Int = 0
    var j: Int = 0

    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        cv.setNeedsDisplay()
    }

    override init(frame: CGRect) {

        super.init(frame: frame)

        cv.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cv)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: cv.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: cv.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: cv.trailingAnchor),
        ])

        func createView() -> UIView {
            let v = UIView()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.backgroundColor = .black
            contentView.addSubview(v)
            return v
        }

        horizontals = [
            createView(),
            createView(),
            createView(),
            createView(),
        ]

        verticals = [
            createView(),
            createView(),
            createView(),
            createView(),
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private class ContentView: UIView {

        unowned var fiveXfive: FiveXFive!

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .white
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draw(_ rect: CGRect) {
            guard let ctx = UIGraphicsGetCurrentContext() else { return }

            for i in 0..<5 {
                for j in 0..<5 {
                    let point = fiveXfive.delegate!.fiveXFive(fiveXfive, pointForI: i, J: j)
                    switch point.value {
                    case .color(let c):
                        ctx.setFillColor(c.c.cgColor)
                        let rectangle: CGRect = CGRect(
                            x: fiveXfive.cellAspectSize * CGFloat(i),
                            y: fiveXfive.cellAspectSize * CGFloat(j),
                            width: fiveXfive.cellAspectSize,
                            height: fiveXfive.cellAspectSize
                        )
                        ctx.fill(rectangle)
                    case .empty:
                        ctx.setFillColor(UIColor.black.cgColor)
                        let rectangle: CGRect = CGRect(
                            x: fiveXfive.cellAspectSize * CGFloat(i) + fiveXfive.cellAspectSize/2 - 2,
                            y: fiveXfive.cellAspectSize * CGFloat(j) + fiveXfive.cellAspectSize/2 - 2,
                            width: 4,
                            height: 4
                        )
                        ctx.fillEllipse(in: rectangle)
                    case .none:
                        break
                    }
                }
            }
        }
    }

    let cellAspectSize: CGFloat = 20

    private let cv = ContentView()

    override func layoutSubviews() {
        super.layoutSubviews()

        horizontals.enumerated().forEach { i, v in
            v.frame = CGRect(
                x: 0,
                y: CGFloat(i + 1) * (bounds.height / 5),
                width: bounds.width,
                height: 1/UIScreen.main.scale
            )
        }

        verticals.enumerated().forEach { i, v in
            v.frame = CGRect(
                x: CGFloat(i + 1) * (bounds.height / 5),
                y: 0,
                width: 1/UIScreen.main.scale,
                height: bounds.height
            )
        }

        let tapGR = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        addGestureRecognizer(tapGR)

        cv.fiveXfive = self
    }

    @objc private func tap(_ tapGR: UITapGestureRecognizer) {
        let location = tapGR.location(in: self)
        delegate?.fiveXFive(self, didTapI: Int(location.x / cellAspectSize), J: Int(location.y / cellAspectSize))
        cv.setNeedsDisplay()
    }
}

class NumbersView: CellView {

    var axis: NSLayoutConstraint.Axis = .horizontal {
        didSet {
            cv.axis = axis
        }
    }

    var cellAspectSize: CGFloat = 1 {
        didSet {
            cv.cellAspectSize = cellAspectSize
        }
    }

    private class ContentView: UIView {

        var axis: NSLayoutConstraint.Axis = .horizontal {
            didSet {
                setNeedsDisplay()
            }
        }

        var cellAspectSize: CGFloat = 1 {
            didSet {
                setNeedsDisplay()
            }
        }

        var numbers: [[Field.Definition]] = [] {
            didSet {
                setNeedsDisplay()
            }
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .white
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draw(_ rect: CGRect) {
            guard let ctx = UIGraphicsGetCurrentContext() else { return }

            let max = numbers.reduce(0) { partialResult, line in
                if line.count > partialResult {
                    return line.count
                }
                return partialResult
            }

            for (j, line) in numbers.enumerated() {
                for (i, def) in line.reversed().enumerated() {
                    ctx.setFillColor(def.color.c.cgColor)
                    let rectangle: CGRect
                    if axis == .horizontal {
                        rectangle = CGRect(
                            x: cellAspectSize * CGFloat(max - i - 1),
                            y: cellAspectSize * CGFloat(j),
                            width: cellAspectSize,
                            height: cellAspectSize
                        )
                    } else {
                        rectangle = CGRect(
                            x: cellAspectSize * CGFloat(j),
                            y: cellAspectSize * CGFloat(max - i - 1),
                            width: cellAspectSize,
                            height: cellAspectSize
                        )
                    }
                    ctx.fill(rectangle)

                    var white: CGFloat = 0
                    var alpha: CGFloat = 0
                    def.color.c.getWhite(&white, alpha: &alpha)

                    if white > 0.5 {
                        white = 0
                    } else {
                        white = 1
                    }

                    let textColor = UIColor(white: white, alpha: alpha)

                    let font = UIFont.systemFont(ofSize: 12)
                    let string = NSAttributedString(
                        string: "\(def.n)",
                        attributes: [
                            NSAttributedString.Key.font: font,
                            NSAttributedString.Key.foregroundColor: textColor
                        ])
                    string.draw(at: CGPoint(
                        x: rectangle.origin.x + 7,
                        y: rectangle.origin.y + 3
                    ))
                }
            }
        }
    }

    var numbers: [[Field.Definition]] = [] {
        didSet {
            cv.numbers = numbers
        }
    }

    private let cv = ContentView()

    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        cv.setNeedsDisplay()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        cv.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cv)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: cv.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: cv.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: cv.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol MenuViewDelegate: AnyObject {
    func menuViewPresentingViewController(_: MenuView) -> UIViewController
    func menuView(_: MenuView, didSelectPen: Pen)
}

class MenuView: UIView {

    weak var delegate: MenuViewDelegate?

    private let empty = UIButton()
    private let color = UIButton()
    private let layerB = UIButton()

    var pen: Pen = .empty {
        didSet {
            update()
        }
    }

    private func update() {
        empty.backgroundColor = .clear
        color.backgroundColor = .clear
        layerB.backgroundColor = .clear

        switch pen {
        case .empty:
            empty.backgroundColor = .gray
        case .color(let c):
            color.backgroundColor = c.c
        case .layer(let c):
            layerB.backgroundColor = c.c
        }
    }

    var colors: [Field.Color] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        empty.setTitle("E", for: .normal)
        empty.setTitleColor(.black, for: .normal)
        empty.addTarget(self, action: #selector(tapEmpty), for: .touchUpInside)
        stackView.addArrangedSubview(empty)

        color.setTitle("C", for: .normal)
        color.addTarget(self, action: #selector(tapColor), for: .touchUpInside)
        color.setTitleColor(.black, for: .normal)
        stackView.addArrangedSubview(color)

        layerB.setTitle("L", for: .normal)
        layerB.addTarget(self, action: #selector(tapLayer), for: .touchUpInside)
        layerB.setTitleColor(.black, for: .normal)
        stackView.addArrangedSubview(layerB)

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        update()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class SelectColorViewController: UIViewController {

        var colors: [Field.Color] = []

        var didSelect: ((_ index: Int) -> Void)?

        override func loadView() {
            view = UIStackView()
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            let stackView = view as! UIStackView
            stackView.axis = .vertical

            for color in colors {
                let v = UIView()
                v.backgroundColor = color.c
                stackView.addArrangedSubview(v)

                let tapGR = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
                v.addGestureRecognizer(tapGR)

                NSLayoutConstraint.activate([
                    v.widthAnchor.constraint(equalToConstant: 50),
                    v.heightAnchor.constraint(equalToConstant: 50),
                ])
            }

            preferredContentSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        }

        @objc private func didTap(_ tapGR: UITapGestureRecognizer) {
            let i = ((view as! UIStackView).arrangedSubviews.firstIndex(where: { $0 === tapGR.view }))!
            didSelect?(i)
        }
    }

    @objc private func tapEmpty() {
        delegate?.menuView(self, didSelectPen: .empty)
    }

    var popoverContentController: SelectColorViewController?
    @objc private func tapColor() {
        let popoverContentController = SelectColorViewController()
        self.popoverContentController = popoverContentController
        popoverContentController.colors = colors
        popoverContentController.modalPresentationStyle = .popover
        popoverContentController.didSelect = { [weak self] i in
            self?.popoverContentController?.dismiss(animated: true)
            self?.popoverContentController = nil
            self?.delegate?.menuView(self!, didSelectPen: .color(self!.colors[i]))
        }

        if let popoverPresentationController = popoverContentController.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .right
            popoverPresentationController.sourceView = self
            popoverPresentationController.sourceRect = color.frame

            let presentingViewController = delegate?.menuViewPresentingViewController(self)
            presentingViewController?.present(popoverContentController, animated: true, completion: nil)
        }
    }

    @objc private func tapLayer() {
        let popoverContentController = SelectColorViewController()
        self.popoverContentController = popoverContentController
        popoverContentController.colors = colors
        popoverContentController.modalPresentationStyle = .popover
        popoverContentController.didSelect = { [weak self] i in
            self?.popoverContentController?.dismiss(animated: true)
            self?.popoverContentController = nil
            self?.delegate?.menuView(self!, didSelectPen: .layer(self!.colors[i]))
        }

        if let popoverPresentationController = popoverContentController.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .right
            popoverPresentationController.sourceView = self
            popoverPresentationController.sourceRect = layerB.frame

            let presentingViewController = delegate?.menuViewPresentingViewController(self)
            presentingViewController?.present(popoverContentController, animated: true, completion: nil)
        }
    }
}

enum Pen {
    case empty
    case color(Field.Color)
    case layer(Field.Color)
}

class ViewController: UIViewController, UIScrollViewDelegate, MenuViewDelegate, FiveXFiveDelegate {

    func fiveXFive(_ fiveXfive: FiveXFive, pointForI i: Int, J j: Int) -> Field.Point {
        if fiveXfive.i * 5 + i >= field.size.w || fiveXfive.j * 5 + j >= field.size.h {
            return .init(value: .none)
        }
        return field.points[fiveXfive.j * 5 + j][fiveXfive.i * 5 + i]
    }

    func fiveXFive(_ fiveXfive: FiveXFive, didTapI i: Int, J j: Int) {
        switch pen {
        case .empty:
            field.points[fiveXfive.j * 5 + j][fiveXfive.i * 5 + i] = .init(value: .empty)
        case .color(let c):
            field.points[fiveXfive.j * 5 + j][fiveXfive.i * 5 + i] = .init(value: .color(c))
        case .layer(let c):
            field.points[fiveXfive.j * 5 + j][fiveXfive.i * 5 + i] = .init(value: .color(c))
        }
    }

    var pen: Pen = .empty {
        didSet {
            menuView.pen = pen
        }
    }

    func menuViewPresentingViewController(_: MenuView) -> UIViewController {
        return self
    }

    func menuView(_: MenuView, didSelectPen pen: Pen) {
        self.pen = pen

        if case .layer(let penColor) = pen {
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
                    if case .color(let c) = p.value, c.id == penColor.id {
                        field.points[i][j] = p
                    }
                    if case .empty = p.value {
                        field.points[i][j] = p
                    }
                }
            }

            layerColorId = penColor.id
        }
        if case .color = pen, layerColorId != nil {
            layers[layerColorId!] = field
            field = sourceField

            for (i, line) in layers[layerColorId!]!.points.enumerated() {
                for (j, p) in line.enumerated() {
                    if case .color(let c) = p.value, c.id == layerColorId {
                        field.points[i][j] = p
                    }
                }
            }

            layerColorId = nil
        }

        fiveXfives.forEach { element in
            element.setNeedsDisplay()
        }
        horizontalsCell.numbers = field.horizintals
        horizontalsCell.setNeedsDisplay()
        verticalsCell.numbers = field.verticals
        verticalsCell.setNeedsDisplay()
    }

    let scrollView = UIScrollView()
    let contentView = CellView()
    let menuView = MenuView()

    var field: Field!

    var sourceField: Field!
    var layers: [String: Field] = [:]
    var layerColorId: String?

    let horizontalsCell = NumbersView()
    let verticalsCell = NumbersView()
    var fiveXfives: [FiveXFive] = []

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

        field = Field(
            points: Array<[Field.Point]>(
                repeating: Array<Field.Point>(repeating: .init(value: nil), count: 14),
                count: 20
            ),
            horizintals: [
                [
                    .init(color: .init(c: .lightGray), n: 4),
                ],
                [
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                ],
                [
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                ],
                [
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                ],
                [
                    .init(color: .init(c: .yellow), n: 4),
                    .init(color: .init(c: .lightGray), n: 1),
                ],

                [
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                ],
                [
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                ],
                [
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .lightGray), n: 2),
                ],
                [
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                ],
                [
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .black), n: 2),
                ],

                [
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .lightGray), n: 2),
                    .init(color: .init(c: .black), n: 1),
                ],
                [
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .lightGray), n: 4),
                    .init(color: .init(c: .black), n: 1),
                ],
                [
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .lightGray), n: 5),
                    .init(color: .init(c: .black), n: 1),
                ],
                [
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .black), n: 2),
                    .init(color: .init(c: .lightGray), n: 2),
                    .init(color: .init(c: .black), n: 1),
                ],
                [
                    .init(color: .init(c: .lightGray), n: 2),
                    .init(color: .init(c: .black), n: 2),
                    .init(color: .init(c: .lightGray), n: 1),
                ],

                [
                    .init(color: .init(c: .lightGray), n: 2),
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                ],
                [
                    .init(color: .init(c: .lightGray), n: 4),
                    .init(color: .init(c: .yellow), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .lightGray), n: 2),
                ],
                [
                    .init(color: .init(c: .yellow), n: 1),
                    .init(color: .init(c: .yellow), n: 1),
                    .init(color: .init(c: .lightGray), n: 4),
                ],
                [
                    .init(color: .init(c: .yellow), n: 1),
                    .init(color: .init(c: .yellow), n: 1),
                ],
                [
                    .init(color: .init(c: .yellow), n: 7),
                ],
            ],
            verticals: [
                [
                    .init(color: .init(c: .yellow), n: 1),
                    .init(color: .init(c: .black), n: 3),
                ],
                [
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .yellow), n: 1),
                    .init(color: .init(c: .lightGray), n: 5),
                    .init(color: .init(c: .lightGray), n: 2),
                ],
                [
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .yellow), n: 1),
                    .init(color: .init(c: .lightGray), n: 2),
                    .init(color: .init(c: .yellow), n: 1),
                ],
                [
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .yellow), n: 1),
                    .init(color: .init(c: .lightGray), n: 2),
                    .init(color: .init(c: .yellow), n: 1),
                ],
                [
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .yellow), n: 3),
                ],

                [
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .yellow), n: 1),
                ],
                [
                    .init(color: .init(c: .lightGray), n: 7),
                    .init(color: .init(c: .black), n: 2),
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .yellow), n: 1),
                ],
                [
                    .init(color: .init(c: .lightGray), n: 2),
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .lightGray), n: 2),
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .yellow), n: 4),
                ],
                [
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .lightGray), n: 3),
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .yellow), n: 1),
                ],
                [
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .lightGray), n: 4),
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                ],

                [
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .lightGray), n: 3),
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                ],
                [
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                    .init(color: .init(c: .lightGray), n: 1),
                ],
                [
                    .init(color: .init(c: .black), n: 1),
                    .init(color: .init(c: .lightGray), n: 3),
                ],
                [
                    .init(color: .init(c: .lightGray), n: 1),
                ],
            ])

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

        let cellAspectSize: CGFloat = 20

        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalToConstant: CGFloat(hMax + field.size.w) * cellAspectSize),
            contentView.heightAnchor.constraint(equalToConstant: CGFloat(vMax + field.size.h) * cellAspectSize),
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

        horizontalsCell.cellAspectSize = cellAspectSize
        horizontalsCell.numbers = field.horizintals
        horizontalsCell.axis = .horizontal
        horizontalsCell.translatesAutoresizingMaskIntoConstraints = false
        contentView.contentView.addSubview(horizontalsCell)
        NSLayoutConstraint.activate([
            horizontalsCell.topAnchor.constraint(equalTo: contentView.topAnchor, constant: CGFloat(vMax) * cellAspectSize),
            horizontalsCell.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            horizontalsCell.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            horizontalsCell.widthAnchor.constraint(equalToConstant: CGFloat(hMax) * cellAspectSize),
        ])

        verticalsCell.cellAspectSize = cellAspectSize
        verticalsCell.numbers = field.verticals
        verticalsCell.axis = .vertical
        verticalsCell.translatesAutoresizingMaskIntoConstraints = false
        contentView.contentView.addSubview(verticalsCell)
        NSLayoutConstraint.activate([
            verticalsCell.topAnchor.constraint(equalTo: contentView.topAnchor),
            verticalsCell.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: CGFloat(hMax) * cellAspectSize),
            verticalsCell.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            verticalsCell.heightAnchor.constraint(equalToConstant: CGFloat(vMax) * cellAspectSize),
        ])

        for i in 0..<((field.size.w / 5) + 1) {
            for j in 0..<((field.size.h / 5) + 1) {
                let fiveXfiveCell = FiveXFive()
                fiveXfiveCell.i = i
                fiveXfiveCell.j = j
                contentView.contentView.addSubview(fiveXfiveCell)

                fiveXfives.append(fiveXfiveCell)

                fiveXfiveCell.delegate = self

                fiveXfiveCell.frame = CGRect(
                    x: CGFloat(hMax) * cellAspectSize + CGFloat(i * 5) * cellAspectSize,
                    y: CGFloat(vMax) * cellAspectSize + CGFloat(j * 5) * cellAspectSize,
                    width: CGFloat(5) * cellAspectSize,
                    height: CGFloat(5) * cellAspectSize
                )
            }
        }

        menuView.colors = field.colors
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuView.delegate = self
        view.addSubview(menuView)

        NSLayoutConstraint.activate([
            menuView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            menuView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }

}
