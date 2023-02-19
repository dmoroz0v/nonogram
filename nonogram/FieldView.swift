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

    private(set) var horizontalLinesHunksCell: LinesHunksView!
    private(set) var verticalLinesHunksCell: LinesHunksView!
    private(set) var solutionView: SolutionView!

    init(frame: CGRect, field: Field) {
        size = field.size
        super.init(frame: frame)

        solutionView = SolutionView(frame: .zero, panView: self)

        horizontalLinesHunksCell = LinesHunksView(frame: .zero, panView: self)
        verticalLinesHunksCell = LinesHunksView(frame: .zero, panView: self)

//        let maxHorizintalHunks = field.horizintalLinesHunks.reduce(0) { value, hunks in
//            if hunks.count > value {
//                return hunks.count
//            }
//            return value
//        }
//        let maxVerticalHunks = field.verticalLinesHunks.reduce(0) { value, hunks in
//            if hunks.count > value {
//                return hunks.count
//            }
//            return value
//        }

        let leftTopCell = CellView()
        leftTopCell.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftTopCell)

        solutionView.translatesAutoresizingMaskIntoConstraints = false
        solutionView.size = field.size
        solutionView.cellAspectSize = cellAspectSize
        addSubview(solutionView)

        horizontalLinesHunksCell.translatesAutoresizingMaskIntoConstraints = false
        horizontalLinesHunksCell.cellAspectSize = cellAspectSize
        horizontalLinesHunksCell.linesHunks = field.horizintalLinesHunks
        horizontalLinesHunksCell.axis = .horizontal
        addSubview(horizontalLinesHunksCell)

        verticalLinesHunksCell.translatesAutoresizingMaskIntoConstraints = false
        verticalLinesHunksCell.cellAspectSize = cellAspectSize
        verticalLinesHunksCell.linesHunks = field.verticalLinesHunks
        verticalLinesHunksCell.axis = .vertical
        addSubview(verticalLinesHunksCell)

        NSLayoutConstraint.activate([
            leftTopCell.topAnchor.constraint(equalTo: topAnchor),
            leftTopCell.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftTopCell.widthAnchor.constraint(equalTo: horizontalLinesHunksCell.widthAnchor),
            leftTopCell.heightAnchor.constraint(equalTo: verticalLinesHunksCell.heightAnchor),

            horizontalLinesHunksCell.topAnchor.constraint(equalTo: leftTopCell.bottomAnchor),
            horizontalLinesHunksCell.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalLinesHunksCell.bottomAnchor.constraint(equalTo: bottomAnchor),

            verticalLinesHunksCell.topAnchor.constraint(equalTo: topAnchor),
            verticalLinesHunksCell.leadingAnchor.constraint(equalTo: leftTopCell.trailingAnchor),
            verticalLinesHunksCell.trailingAnchor.constraint(equalTo: trailingAnchor),

            solutionView.topAnchor.constraint(equalTo: verticalLinesHunksCell.bottomAnchor),
            solutionView.leadingAnchor.constraint(equalTo: horizontalLinesHunksCell.trailingAnchor),
            solutionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            solutionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            solutionView.widthAnchor.constraint(equalToConstant: CGFloat(field.size.columns) * cellAspectSize),
            solutionView.heightAnchor.constraint(equalToConstant: CGFloat(field.size.rows) * cellAspectSize),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
