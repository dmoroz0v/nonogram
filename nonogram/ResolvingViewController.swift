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

class ResolvingViewController: UIViewController, UIScrollViewDelegate, MenuViewDelegate, FiveXFiveDelegate {

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

    var horizintals: [[Field.Definition]]
    var verticals: [[Field.Definition]]

    init(
        horizintals: [[Field.Definition]],
        verticals: [[Field.Definition]]
    ) {
        self.horizintals = horizintals
        self.verticals = verticals
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

        field = Field(
            points: Array<[Field.Point]>(
                repeating: Array<Field.Point>(repeating: .init(value: nil), count: verticals.count),
                count: horizintals.count
            ),
            horizintals: horizintals,
            verticals: verticals)

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
