//
//  FieldView.swift
//  nonogram
//
//  Created by Denis S. Morozov on 29.01.2023.
//

import Foundation
import UIKit

final class FieldView: UIView {
    private let cellAspectSize: CGFloat = 15
    private let size: (columns: Int, rows: Int)

    private(set) var horizontalDefsCell: NumbersView!
    private(set) var verticalDefsCell: NumbersView!
    private(set) var solutionView: SolutionView!

    init(frame: CGRect, field: Field) {
        size = field.size
        super.init(frame: frame)

        solutionView = SolutionView(frame: .zero, panView: self)

        horizontalDefsCell = NumbersView(frame: .zero, panView: self)
        verticalDefsCell = NumbersView(frame: .zero, panView: self)

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
        addSubview(leftTopCell)

        solutionView.translatesAutoresizingMaskIntoConstraints = false
        solutionView.size = field.size
        solutionView.cellAspectSize = cellAspectSize
        addSubview(solutionView)

        horizontalDefsCell.translatesAutoresizingMaskIntoConstraints = false
        horizontalDefsCell.cellAspectSize = cellAspectSize
        horizontalDefsCell.defs = field.horizintals
        horizontalDefsCell.offset = maxHorizintalDefs
        horizontalDefsCell.axis = .horizontal
        addSubview(horizontalDefsCell)

        verticalDefsCell.translatesAutoresizingMaskIntoConstraints = false
        verticalDefsCell.cellAspectSize = cellAspectSize
        verticalDefsCell.defs = field.verticals
        verticalDefsCell.offset = maxVerticalDefs
        verticalDefsCell.axis = .vertical
        addSubview(verticalDefsCell)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(
                equalToConstant: CGFloat(maxHorizintalDefs + field.size.columns) * cellAspectSize),
            heightAnchor.constraint(
                equalToConstant: CGFloat(maxVerticalDefs + field.size.rows) * cellAspectSize),

            leftTopCell.topAnchor.constraint(equalTo: topAnchor),
            leftTopCell.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftTopCell.widthAnchor.constraint(equalToConstant: CGFloat(maxHorizintalDefs) * cellAspectSize),
            leftTopCell.heightAnchor.constraint(equalToConstant: CGFloat(maxVerticalDefs) * cellAspectSize),

            horizontalDefsCell.topAnchor.constraint(equalTo: leftTopCell.bottomAnchor),
            horizontalDefsCell.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalDefsCell.bottomAnchor.constraint(equalTo: bottomAnchor),
            horizontalDefsCell.widthAnchor.constraint(equalToConstant: CGFloat(maxHorizintalDefs) * cellAspectSize),

            verticalDefsCell.topAnchor.constraint(equalTo: topAnchor),
            verticalDefsCell.leadingAnchor.constraint(equalTo: leftTopCell.trailingAnchor),
            verticalDefsCell.trailingAnchor.constraint(equalTo: trailingAnchor),
            verticalDefsCell.heightAnchor.constraint(equalToConstant: CGFloat(maxVerticalDefs) * cellAspectSize),

            solutionView.topAnchor.constraint(equalTo: verticalDefsCell.bottomAnchor),
            solutionView.leadingAnchor.constraint(equalTo: horizontalDefsCell.trailingAnchor),
            solutionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            solutionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
