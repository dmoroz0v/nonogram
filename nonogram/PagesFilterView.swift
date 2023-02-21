//
//  PagesFilterView.swift
//  nonogram
//
//  Created by Denis S. Morozov on 19.02.2023.
//

import Foundation
import UIKit

final class PagesFilterView: UIView {
    let label = UILabel()

    var isSelected = false {
        didSet {
            if isSelected {
                backgroundColor = .lightGray
            } else {
                backgroundColor = UIColor(white: 0.85, alpha: 1)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        layer.masksToBounds = true
        layer.cornerRadius = 16
        backgroundColor = UIColor(white: 0.85, alpha: 1)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
