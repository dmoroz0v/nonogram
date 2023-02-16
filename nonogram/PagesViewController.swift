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
    func pagesViewController(_: PagesViewController, didSelectItem: ListItem, savedData: Storage.Data?)
}

private extension Elements {
    func tryFirst() throws -> Element {
        if let first = first() {
            return first
        }
        throw NSError()
    }
}

final class ControlsView: UIView {

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

final class PagesLoader {

    struct Result {
        var items: [ListItem]
        var pagesCount: Int
    }

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

    func loadPage(_ page: Int, filter: Filter, completaion: @escaping (_ items: Result?) -> Void) {
        if isLoading {
            return
        }
        isLoading = true
        DispatchQueue.global().async {
            do {
                let data = try Data(contentsOf: filter.url.appendingPathComponent("\(page)"))

                if let s = String(data: data, encoding: .utf8) {
                    let doc: Document = try SwiftSoup.parse(s)

                    var result: [ListItem] = []
                    for tr in try doc.select("table.nonogram_list").tryFirst().select("tr") {
                        let nonogramImg = try tr.select("td.nonogram_img")
                        if let nonogramImg = nonogramImg.first() {
                            let urlString = try nonogramImg.select("a").tryFirst().attr("href")
                            var iconUrlString = try nonogramImg.select("img").tryFirst().attr("src")
                            iconUrlString = iconUrlString.replacingOccurrences(of: "_0.png", with: "_1.png")
                            let name = try nonogramImg.select("img").tryFirst().attr("title")
                            if let url = URL(string: urlString), let thumbnailUrl = URL(string: iconUrlString) {
                                result.append(ListItem(url: url, thumbnailUrl: thumbnailUrl, title: name))
                            }
                        }
                    }

                    let pages = try doc.select("div.pager").tryFirst().select("div").tryFirst().select("a")

                    var pagesCount: Int?
                    for a in pages.reversed() {
                        if let count = Int(try a.text()) {
                            pagesCount = count
                            break
                        }
                    }

                    guard let pagesCount else {
                        DispatchQueue.main.async {
                            self.isLoading = false
                            completaion(nil)
                        }
                        return
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
                        completaion(Result(items: result, pagesCount: pagesCount))
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
            updateUI()
        }
    }

    private var selectedFilter: PagesLoader.Filter {
        return pagesLoader.filters[state.currentFilter]
    }

    private let controlsView = ControlsView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private let storage: Storage

    init(storage: Storage) {
        self.storage = storage
        let state = stateManager.loadState()
        if let state, stateManager.isValid(state: state, with: pagesLoader.filters) {
            self.state = state
        } else {
            self.state = State(currentFilter: 0, filters: pagesLoader.filters.map({
                .init(name: $0.name, page: 1)
            }))
        }
        super.init(nibName: nil, bundle: nil)
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

        controlsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsView)
        controlsView.prevPageButton.addTarget(self, action: #selector(prevPage), for: .touchDown)
        controlsView.nextPageButton.addTarget(self, action: #selector(nextPage), for: .touchDown)
        controlsView.lastButton.addTarget(self, action: #selector(recently), for: .touchDown)

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
            listViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            controlsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            controlsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        listViewController.scrollView.contentInset = .init(top: 0, left: 0, bottom: 24 + 48 + 24, right: 0)

        updateUI()
        loadCurrentPage()
    }

    @objc private func prevPage() {
        state.currentPage -= 1
    }

    @objc private func nextPage() {
        state.currentPage += 1
    }

    @objc private func recently() {
        let recentlyViewController = RecentlyViewController(storage: storage)
        recentlyViewController.delegate = self
        present(recentlyViewController, animated: true)
    }

    @objc private func selectFilter(_ tapGR: UITapGestureRecognizer) {
        guard let filterIndex = tapGR.view?.tag else {
            return
        }
        if selectedFilter != pagesLoader.filters[filterIndex] {
            state.currentFilter = filterIndex
        }
    }


    private func show(items: [ListItem]) {
        listViewController.items = items
        controlsView.prevPageButton.isEnabled = state.currentPage > 1
    }

    private func updateUI() {
        controlsView.currentPageButton.setTitle("\(state.currentPage)", for: .normal)
        controlsView.lastButton.isEnabled = storage.hasRecently()
        for (filterIndex, filterView) in filtersStackView.arrangedSubviews.enumerated() {
            (filterView as! FilterView).isSelected = selectedFilter == pagesLoader.filters[filterIndex]
        }
    }

    private func loadCurrentPage() {
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        view.alpha = 0.5
        pagesLoader.loadPage(state.currentPage, filter: selectedFilter) { result in
            self.view.isUserInteractionEnabled = true
            self.activityIndicator.stopAnimating()
            self.view.alpha = 1
            if let result = result {
                self.show(items: result.items)
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
        if let data = storage.load(key: item.url.absoluteString) {
            let alert = UIAlertController(title: nil, message: "", preferredStyle: .alert)
            alert.addAction(.init(title: "Новая", style: .default, handler: { _ in
                self.delegate?.pagesViewController(self, didSelectItem: item, savedData: nil)
            }))
            alert.addAction(.init(title: "Продолжить", style: .default, handler: { _ in
                self.delegate?.pagesViewController(self, didSelectItem: item, savedData: data)
            }))
            alert.addAction(.init(title: "Отмена", style: .destructive))
            present(alert, animated: true)
        } else {
            delegate?.pagesViewController(self, didSelectItem: item, savedData: nil)
        }
    }
}

extension PagesViewController: RecentlyViewControllerDelegate {
    func recentlyViewController(_ recentlyViewController: RecentlyViewController, didSelectItem item: ListItem, savedData: Storage.Data?) {
        recentlyViewController.dismiss(animated: true)
        delegate?.pagesViewController(self, didSelectItem: item, savedData: savedData)
    }
}
