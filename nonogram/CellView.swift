//
//  CellView.swift
//  nonogram
//
//  Created by Denis S. Morozov on 12.01.2023.
//

import Foundation
import UIKit

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
