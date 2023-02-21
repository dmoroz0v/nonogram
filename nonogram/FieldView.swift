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

    private(set) var horizontalLinesHunksCell: LinesHunksView!
    private(set) var verticalLinesHunksCell: LinesHunksView!
    private(set) var solutionView: SolutionView!

    init(
        frame: CGRect,
        solutionSize: (columns: Int, rows: Int),
        verticalMaxHunks: Int,
        horizontalMaxHunks: Int
    ) {
        super.init(frame: frame)

        solutionView = SolutionView(frame: .zero, panView: self)

        horizontalLinesHunksCell = LinesHunksView(frame: .zero, panView: self, maxHunks: horizontalMaxHunks)
        verticalLinesHunksCell = LinesHunksView(frame: .zero, panView: self, maxHunks: verticalMaxHunks)

        let leftTopCell = CellView()
        leftTopCell.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftTopCell)

        solutionView.translatesAutoresizingMaskIntoConstraints = false
        solutionView.size = solutionSize
        solutionView.cellAspectSize = cellAspectSize
        addSubview(solutionView)

        horizontalLinesHunksCell.translatesAutoresizingMaskIntoConstraints = false
        horizontalLinesHunksCell.cellAspectSize = cellAspectSize
        horizontalLinesHunksCell.axis = .horizontal
        addSubview(horizontalLinesHunksCell)

        verticalLinesHunksCell.translatesAutoresizingMaskIntoConstraints = false
        verticalLinesHunksCell.cellAspectSize = cellAspectSize
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
            solutionView.widthAnchor.constraint(equalToConstant: CGFloat(solutionSize.columns) * cellAspectSize),
            solutionView.heightAnchor.constraint(equalToConstant: CGFloat(solutionSize.rows) * cellAspectSize),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
