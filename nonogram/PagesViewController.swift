//
//  PagesViewController.swift
//  nonogram
//
//  Created by Denis S. Morozov on 16.01.2023.
//

import Foundation
import UIKit

protocol PagesViewControllerDelegate: AnyObject {
    func pagesViewController(_: PagesViewController, didSelectItem: ListItem, savedData: Storage.Data?)
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

    private let controlsView = PagesControlsView()
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
            let filterView = PagesFilterView()
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
            (filterView as! PagesFilterView).isSelected = selectedFilter == pagesLoader.filters[filterIndex]
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
