//
//  PagesViewController.swift
//  nonogram
//
//  Created by Denis S. Morozov on 16.01.2023.
//

import Foundation
import UIKit
import SwiftSoup
import SwiftUI

protocol PagesViewControllerDelegate: AnyObject {
    func pagesViewController(_: PagesViewController, didSelectItem: ListItem)
}

final class PageButtonsView: UIView {
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
            prevPageButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            prevPageButton.trailingAnchor.constraint(equalTo: centerXAnchor),
            prevPageButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            nextPageButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            nextPageButton.leadingAnchor.constraint(equalTo: centerXAnchor),
            nextPageButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            heightAnchor.constraint(equalToConstant: 64),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class PagesLoader {
    struct Filter: Equatable {
        var name: String
        var url: URL
    }

    let filters: [Filter] = [
        Filter(name: "Все", url: URL(string: "https://www.nonograms.ru/nonograms2/p")!),
        Filter(name: "Крошечные", url: URL(string: "https://www.nonograms.ru/nonograms2/size/xsmall/p")!),
        Filter(name: "Маленькие", url: URL(string: "https://www.nonograms.ru/nonograms2/size/small/p")!),
        Filter(name: "Средние", url: URL(string: "https://www.nonograms.ru/nonograms2/size/medium/p")!),
        Filter(name: "Большие", url: URL(string: "https://www.nonograms.ru/nonograms2/size/large/p")!),
        Filter(name: "Огромные", url: URL(string: "https://www.nonograms.ru/nonograms2/size/xlarge/p")!),
        Filter(name: "Гигантские", url: URL(string: "https://www.nonograms.ru/nonograms2/size/xxlarge/p")!),
    ]

    private var isLoading = false

    func loadPage(_ page: Int, filter: Filter, completaion: @escaping (_ items: [ListItem]?) -> Void) {
        if isLoading {
            return
        }
        isLoading = true
        DispatchQueue.global().async {
            do {
                let data = try Data(contentsOf: filter.url.appendingPathComponent("\(page)"))

                if let s = String(data: data, encoding: .utf8) {
                    let doc: Document = try SwiftSoup.parse(s)
                    let nonogramList = try doc.select("table.nonogram_list").first()!

                    var result: [ListItem] = []

                    for tr in try nonogramList.select("tr") {
                        let nonogramImg = try tr.select("td.nonogram_img").first()
                        let nonogramDescr = try tr.select("td.nonogram_descr").first()
                        if let nonogramImg = nonogramImg, let _ = nonogramDescr {
                            let urlString = try nonogramImg.select("a").first()!.attr("href")
                            var iconUrlString = try nonogramImg.select("img").first()!.attr("src")
                            iconUrlString = iconUrlString.replacingOccurrences(of: "_0.png", with: "_1.png")
                            let name = try nonogramImg.select("img").first()!.attr("title")
                            result.append(ListItem(
                                url: URL(string: urlString)!,
                                thumbnailUrl: URL(string: iconUrlString)!,
                                title: name
                            ))
                        }
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

final class FilterView: UIView {
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

final class PagesViewController: UIViewController {

    private class StateManager {
        func saveState(_ state: State) {
            do {
                let jsonString = String(decoding: try JSONEncoder().encode(state), as: UTF8.self)
                UserDefaults.standard.set(jsonString, forKey: "NanoApp.Pages.State")
                UserDefaults.standard.synchronize()
            } catch {
            }
        }

        func loadState() -> State? {
            do {
                let str = UserDefaults.standard.string(forKey: "NanoApp.Pages.State")
                if let str, let d = str.data(using: .utf8) {
                    return try JSONDecoder().decode(State.self, from: d)
                }
            } catch {
            }
            return nil
        }

        func isValid(state: State, with filters: [PagesLoader.Filter]) -> Bool {
            let stateFilersNames = state.filters.map { $0.name }
            let filtersNames = filters.map { $0.name }
            return stateFilersNames == filtersNames
        }
    }

    private struct State: Codable, Equatable {
        struct Filter: Codable, Equatable {
            var name: String
            var page: Int
        }
        var currentFilter: Int
        var filters: [Filter]

        var currentPage: Int {
            get {
                filters[currentFilter].page
            }
            set {
                filters[currentFilter].page = newValue
            }
        }
    }

    weak var delegate: PagesViewControllerDelegate?

    private var filtersStackView: UIStackView!
    private let listViewController = ListViewController()

    private let pagesLoader = PagesLoader()
    private let stateManager = StateManager()

    private var state: State {
        didSet {
            stateManager.saveState(state)
            loadCurrentPage()
            updateSelectedFilter()
        }
    }

    private var selectedFilter: PagesLoader.Filter {
        return pagesLoader.filters[state.currentFilter]
    }

    private let pageButtonsView = PageButtonsView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let state = stateManager.loadState()
        if let state, stateManager.isValid(state: state, with: pagesLoader.filters) {
            self.state = state
        } else {
            self.state = State(currentFilter: 0, filters: pagesLoader.filters.map({
                .init(name: $0.name, page: 1)
            }))
        }
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        filtersStackView = UIStackView()

        listViewController.delegate = self
        listViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(listViewController)
        view.addSubview(listViewController.view)
        listViewController.didMove(toParent: self)

        pageButtonsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageButtonsView)
        pageButtonsView.prevPageButton.addTarget(self, action: #selector(prevPage), for: .touchDown)
        pageButtonsView.nextPageButton.addTarget(self, action: #selector(nextPage), for: .touchDown)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        let filtersScrollView = UIScrollView()
        filtersScrollView.translatesAutoresizingMaskIntoConstraints = false
        filtersScrollView.showsHorizontalScrollIndicator = false
        filtersScrollView.contentInset = .init(top: 0, left: 16, bottom: 0, right: 16)
        view.addSubview(filtersScrollView)

        filtersStackView.translatesAutoresizingMaskIntoConstraints = false
        filtersStackView.axis = .horizontal
        filtersStackView.alignment = .center
        filtersStackView.spacing = 12
        filtersScrollView.addSubview(filtersStackView)

        pagesLoader.filters.enumerated().forEach { index, filter in
            let filterView = FilterView()
            filterView.label.text = filter.name
            filterView.tag = index
            let tapGR = UITapGestureRecognizer(target: self, action: #selector(selectFilter(_:)))
            filterView.addGestureRecognizer(tapGR)
            filtersStackView.addArrangedSubview(filterView)
        }

        NSLayoutConstraint.activate([
            filtersScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            filtersScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filtersScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            filtersStackView.topAnchor.constraint(equalTo: filtersScrollView.topAnchor),
            filtersStackView.trailingAnchor.constraint(equalTo: filtersScrollView.trailingAnchor),
            filtersStackView.leadingAnchor.constraint(equalTo: filtersScrollView.leadingAnchor),
            filtersStackView.bottomAnchor.constraint(equalTo: filtersScrollView.bottomAnchor),
            filtersStackView.heightAnchor.constraint(equalToConstant: 56),
            filtersStackView.heightAnchor.constraint(equalTo: filtersScrollView.heightAnchor),

            listViewController.view.topAnchor.constraint(equalTo: filtersScrollView.bottomAnchor),
            listViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            listViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listViewController.view.bottomAnchor.constraint(equalTo: pageButtonsView.topAnchor),

            pageButtonsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageButtonsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageButtonsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector:#selector(appMovedToForeground),
                                       name: UIApplication.willEnterForegroundNotification, object: nil)
        updateSelectedFilter()
        loadCurrentPage()
    }

    @objc private func prevPage() {
        state.currentPage -= 1
    }

    @objc private func nextPage() {
        state.currentPage += 1
    }

    @objc private func selectFilter(_ tapGR: UITapGestureRecognizer) {
        guard let filterIndex = tapGR.view?.tag else {
            return
        }
        if selectedFilter != pagesLoader.filters[filterIndex] {
            state.currentFilter = filterIndex
        }
    }

    @objc private func appMovedToForeground() {
        loadCurrentPage()
    }

    private func show(items: [ListItem]) {
        listViewController.items = items
        pageButtonsView.prevPageButton.isEnabled = state.currentPage > 1
    }

    private func updateSelectedFilter() {
        for (filterIndex, filterView) in filtersStackView.arrangedSubviews.enumerated() {
            (filterView as! FilterView).isSelected = selectedFilter == pagesLoader.filters[filterIndex]
        }
    }

    private func loadCurrentPage() {
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        view.alpha = 0.5
        pagesLoader.loadPage(state.currentPage, filter: selectedFilter) { items in
            self.view.isUserInteractionEnabled = true
            self.activityIndicator.stopAnimating()
            self.view.alpha = 1
            if let items = items {
                self.show(items: items)
            } else {
                self.showErrorAlert()
            }
        }
    }

    private func showErrorAlert() {
        let alert = UIAlertController(title: nil, message: "Ошибка", preferredStyle: .alert)
        alert.addAction(.init(title: "Повторить", style: .default, handler: { _ in
            self.loadCurrentPage()
        }))
        present(alert, animated: true)
    }
}

extension PagesViewController: ListViewControllerDelegate {
    func listViewController(_: ListViewController, didSelectItem item: ListItem) {
        delegate?.pagesViewController(self, didSelectItem: item)
    }
}
