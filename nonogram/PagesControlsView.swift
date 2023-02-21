//
//  PagesControlsView.swift
//  nonogram
//
//  Created by Denis S. Morozov on 19.02.2023.
//

import Foundation
import UIKit

final class PagesControlsView: UIView {

    private final class Separator: UIView {
        private let separator = UIView()
        override init(frame: CGRect) {
            super.init(frame: frame)

            separator.translatesAutoresizingMaskIntoConstraints = false
            separator.backgroundColor = .lightGray
            addSubview(separator)

            NSLayoutConstraint.activate([
                separator.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                separator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
                separator.leadingAnchor.constraint(equalTo: leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: trailingAnchor),
                widthAnchor.constraint(equalToConstant: 1)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    let prevPageButton = UIButton()
    let currentPageButton = UIButton()
    let nextPageButton = UIButton()
    let lastButton = UIButton()

    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .white
        layer.cornerRadius = 24
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 16
        layer.shadowOpacity = 0.2

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        addSubview(stackView)

        let font = UIFont.systemFont(ofSize: 18)

        prevPageButton.setTitle("< предыдущая", for: .normal)
        prevPageButton.setTitleColor(.black, for: .normal)
        prevPageButton.setTitleColor(.lightGray, for: .disabled)
        prevPageButton.titleLabel?.font = font

        currentPageButton.setTitleColor(.black, for: .normal)
        currentPageButton.setTitle("1", for: .normal)
        currentPageButton.titleLabel?.font = font

        nextPageButton.setTitle("следующая >", for: .normal)
        nextPageButton.setTitleColor(.black, for: .normal)
        nextPageButton.setTitleColor(.lightGray, for: .disabled)
        nextPageButton.titleLabel?.font = font

        lastButton.setTitle("недавние", for: .normal)
        lastButton.setTitleColor(.black, for: .normal)
        lastButton.setTitleColor(.lightGray, for: .disabled)
        lastButton.titleLabel?.font = font

        let firstSeparator = Separator()
        let secondSeparator = Separator()
        let thirdSeparator = Separator()
        [prevPageButton, firstSeparator, currentPageButton, secondSeparator, nextPageButton, thirdSeparator, lastButton].forEach {
            stackView.addArrangedSubview($0)
        }

        stackView.setCustomSpacing(16, after: prevPageButton)
        stackView.setCustomSpacing(4, after: firstSeparator)
        stackView.setCustomSpacing(4, after: currentPageButton)
        stackView.setCustomSpacing(16, after: secondSeparator)
        stackView.setCustomSpacing(16, after: nextPageButton)
        stackView.setCustomSpacing(16, after: thirdSeparator)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
