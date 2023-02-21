//
//  ListViewController.swift
//  nonogram
//
//  Created by Denis S. Morozov on 16.02.2023.
//

import Foundation
import UIKit

protocol ListViewControllerDelegate: AnyObject {
    func listViewController(_: ListViewController, didSelectItem: ListItem)
}

final class ListViewController: UIViewController {

    weak var delegate: ListViewControllerDelegate?

    private(set) var scrollView: UIScrollView!
    private var stackView: UIStackView!

    var items: [ListItem] = [] {
        didSet {
            updateItems()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView = UIScrollView()
        stackView = UIStackView()

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        scrollView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)


        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        updateItems()
    }

    private func updateItems() {
        guard isViewLoaded else {
            return
        }

        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }

        items.enumerated().forEach { index, item in
            let itemView = ListItemView()
            itemView.imageView.image = item.image
            itemView.nameLabel.text = item.title
            itemView.tag = index

            stackView.addArrangedSubview(itemView)

            let tapGR = UITapGestureRecognizer(target: self, action: #selector(tapItem(_:)))
            itemView.addGestureRecognizer(tapGR)
        }

        scrollView.contentOffset = .zero
    }

    @objc private func tapItem(_ tapGR: UITapGestureRecognizer) {
        guard let view = tapGR.view else {
            return
        }
        delegate?.listViewController(
            self,
            didSelectItem: items[view.tag])
    }
}
