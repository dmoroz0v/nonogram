//
//  ListViewController.swift
//  nonogram
//
//  Created by Denis S. Morozov on 16.01.2023.
//

import Foundation
import UIKit
import SwiftSoup

protocol ListViewControllerDelegate: AnyObject {
    func listViewController(_: ListViewController, selectWithUrl: URL)
}

struct Item {
    var url: URL
    var iocnURL: URL
    var name: String
    var image: UIImage?
}

class PageButtonsView: UIView {
    let prevPageButton = UIButton()
    let nextPageButton = UIButton()
    override init(frame: CGRect) {
        super.init(frame: frame)

        prevPageButton.translatesAutoresizingMaskIntoConstraints = false
        nextPageButton.translatesAutoresizingMaskIntoConstraints = false

        nextPageButton.setTitle("Следующая страница >", for: .normal)
        nextPageButton.setTitleColor(.black, for: .normal)
        prevPageButton.setTitle("< Предыдущая страница", for: .normal)
        prevPageButton.setTitleColor(.black, for: .normal)
        prevPageButton.setTitleColor(.lightGray, for: .disabled)

        addSubview(prevPageButton)
        addSubview(nextPageButton)

        NSLayoutConstraint.activate([
            prevPageButton.topAnchor.constraint(equalTo: topAnchor),
            prevPageButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            prevPageButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            prevPageButton.trailingAnchor.constraint(equalTo: centerXAnchor),

            nextPageButton.topAnchor.constraint(equalTo: topAnchor),
            nextPageButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            nextPageButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            nextPageButton.leadingAnchor.constraint(equalTo: centerXAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ListLoader {
    private let url = "https://www.nonograms.ru/nonograms2/p/"
    private var isLoading = false

    func loadPage(_ page: Int, completaion: @escaping (_ items: [Item]?) -> Void) {
        if isLoading {
            return
        }
        isLoading = true
        DispatchQueue.global().async {
            do {
                let data = try Data(contentsOf: URL(string: self.url + "\(page)")!)

                if let s = String(data: data, encoding: .utf8) {
                    let doc: Document = try SwiftSoup.parse(s)
                    let nonogramList = try doc.select("table.nonogram_list").first()!

                    var result: [Item] = []

                    for tr in try nonogramList.select("tr") {
                        let nonogramImg = try tr.select("td.nonogram_img").first()
                        let nonogramDescr = try tr.select("td.nonogram_descr").first()
                        if let nonogramImg = nonogramImg, let _ = nonogramDescr {
                            let urlString = try nonogramImg.select("a").first()!.attr("href")
                            var iconUrlString = try nonogramImg.select("img").first()!.attr("src")
                            iconUrlString = iconUrlString.replacingOccurrences(of: "_0.png", with: "_1.png")
                            let name = try nonogramImg.select("img").first()!.attr("title")
                            result.append(Item(
                                url: URL(string: urlString)!,
                                iocnURL: URL(string: iconUrlString)!,
                                name: name
                            ))
                        }
                    }

                    let group = DispatchGroup()

                    result.enumerated().forEach { index, item in
                        group.enter()
                        DispatchQueue.global().async {
                            if let data = try? Data(contentsOf: item.iocnURL) {
                                if let image = UIImage(data: data) {
                                    result[index].image = image
                                }
                            }
                            group.leave()
                        }
                    }

                    group.wait()

                    DispatchQueue.main.async {
                        self.isLoading = false
                        completaion(result)
                    }

                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        completaion(nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    completaion(nil)
                }
            }
        }
    }
}

class ListViewController: UIViewController {

    weak var delegate: ListViewControllerDelegate?

    let textField = UITextField()
    let loadButton = UIButton()
    let continueButton = UIButton()

    let listLoader = ListLoader()

    private var currentPage = 1
    private var items: [Item] = []

    let pageButtonsView = PageButtonsView()

    @objc private func appMovedToForeground() {
        loadCurrentPage()
    }

    private func show(items: [Item]) {
        self.items = items

        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }

        items.enumerated().forEach { index, item in
            let itemView = ItemView()
            itemView.imageView.image = item.image
            itemView.nameLabel.text = item.name
            itemView.tag = index

            stackView.addArrangedSubview(itemView)

            let tapGR = UITapGestureRecognizer(target: self, action: #selector(tapItem(_:)))
            itemView.addGestureRecognizer(tapGR)
        }

        pageButtonsView.prevPageButton.isEnabled = currentPage > 1
    }

    let stackView = UIStackView()

    private func loadCurrentPage() {
        listLoader.loadPage(currentPage) { items in
            if let items = items {
                self.show(items: items)
            } else {
                self.loadCurrentPage()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        pageButtonsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageButtonsView)
        pageButtonsView.prevPageButton.addTarget(self, action: #selector(prevPage), for: .touchDown)
        pageButtonsView.nextPageButton.addTarget(self, action: #selector(nextPage), for: .touchDown)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: pageButtonsView.topAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            scrollView.widthAnchor.constraint(equalTo: stackView.widthAnchor),

            pageButtonsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageButtonsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageButtonsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector:#selector(appMovedToForeground),
                                       name: UIApplication.willEnterForegroundNotification, object: nil)

        loadCurrentPage()
    }

    @objc private func tapItem(_ tapGR: UITapGestureRecognizer) {
        let index = tapGR.view?.tag ?? 0
        let url = items[index].url
        delegate?.listViewController(self, selectWithUrl: url)
    }

    @objc private func prevPage() {
        currentPage -= 1
        loadCurrentPage()
    }

    @objc private func nextPage() {
        currentPage += 1
        loadCurrentPage()
    }
}

class ItemView: UIView {
    let imageView = UIImageView()
    let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.numberOfLines = 0
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        addSubview(imageView)
        addSubview(nameLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),

            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
