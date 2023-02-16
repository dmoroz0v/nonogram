//
//  RecentlyViewController.swift
//  nonogram
//
//  Created by Denis S. Morozov on 16.02.2023.
//

import Foundation
import UIKit

final class RecentryItemsLoader {
    private let storage: Storage

    init(storage: Storage) {
        self.storage = storage
    }

    func load(completion: @escaping (_ result: [ListItem]?) -> Void) {
        DispatchQueue.global().async {
            var result: [ListItem] = []
            for data in self.storage.recenty() {
                result.append(ListItem(url: data.url, thumbnailUrl: data.thumbnailUrl, title: data.title))
            }

            let group = DispatchGroup()

            result.enumerated().forEach { index, item in
                group.enter()
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: item.thumbnailUrl) {
                        if let image = UIImage(data: data) {
                            result[index].image = image
                        }
                    }
                    group.leave()
                }
            }

            group.wait()

            DispatchQueue.main.async {
                completion(result)
            }
        }

    }
}

protocol RecentlyViewControllerDelegate: AnyObject {
    func recentlyViewController(_: RecentlyViewController, didSelectItem: ListItem, savedData: Storage.Data?)
}

final class RecentlyViewController: UIViewController {

    weak var delegate: RecentlyViewControllerDelegate?

    private let storage: Storage
    private let loader: RecentryItemsLoader
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let listViewController = ListViewController()

    init(storage: Storage) {
        self.storage = storage
        loader = RecentryItemsLoader(storage: storage)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        listViewController.delegate = self
        listViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(listViewController)
        view.addSubview(listViewController.view)
        listViewController.didMove(toParent: self)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            listViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            listViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            listViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        load()
    }

    private func load() {
        activityIndicator.startAnimating()
        loader.load { result in
            self.activityIndicator.stopAnimating()
            if let result = result {
                self.listViewController.items = result
            } else {
                self.showErrorAlert()
            }
        }
    }

    private func showErrorAlert() {
        let alert = UIAlertController(title: nil, message: "Ошибка", preferredStyle: .alert)
        alert.addAction(.init(title: "Повторить", style: .default, handler: { _ in
            self.load()
        }))
        present(alert, animated: true)
    }
}

extension RecentlyViewController: ListViewControllerDelegate {
    func listViewController(_: ListViewController, didSelectItem item: ListItem) {
        if let data = storage.load(key: item.url.absoluteString) {
            let alert = UIAlertController(title: nil, message: "", preferredStyle: .alert)
            alert.addAction(.init(title: "Новая", style: .default, handler: { _ in
                self.delegate?.recentlyViewController(self, didSelectItem: item, savedData: nil)
            }))
            alert.addAction(.init(title: "Продолжить", style: .default, handler: { _ in
                self.delegate?.recentlyViewController(self, didSelectItem: item, savedData: data)
            }))
            alert.addAction(.init(title: "Отмена", style: .destructive))
            present(alert, animated: true)
        } else {
            delegate?.recentlyViewController(self, didSelectItem: item, savedData: nil)
        }
    }
}
