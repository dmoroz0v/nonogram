//
//  ViewController.swift
//  nonogram
//
//  Created by Denis S. Morozov on 12.01.2023.
//

import UIKit

extension String {
    public func matching(_ pattern: String, options: NSRegularExpression.Options = []) -> [String] {
        guard let regEx = try? NSRegularExpression(pattern: pattern, options: options) else {
            return []
        }

        return regEx.matches(in: self, range: NSRange(location: 0, length: count)).map { match in
            guard let range = Range(match.range) else {
                return ""
            }
            let startIndex = index(self.startIndex, offsetBy: range.startIndex)
            let endIndex = index(self.startIndex, offsetBy: range.endIndex)
            return String(self[startIndex..<endIndex])
        }
    }
}

class ViewController: UIViewController, ResolvingViewControllerDelegate, ListViewControllerDelegate {

    var currentViewController: UIViewController?

    let crosswordLoader = CrosswordLoader()

    func listViewController(_: ListViewController, selectWithUrl url: URL) {
        if let data = storage.load(key: url.absoluteString) {
            let alert = UIAlertController(title: nil, message: "", preferredStyle: .alert)
            alert.popoverPresentationController?.sourceView = view
            alert.addAction(.init(title: "Новая", style: .default, handler: { _ in
                self.loadCrossword(url: url)
            }))
            alert.addAction(.init(title: "Продолжить", style: .default, handler: { _ in
                let resolvingViewController = ResolvingViewController(
                    url: url,
                    field: data.field,
                    layers: data.layers,
                    currentLayer: data.currentLayer,
                    solution: data.solution,
                    colors: data.colors
                )

                resolvingViewController.delegate = self

                self.showVC(resolvingViewController)
            }))
            alert.addAction(.init(title: "Отмена", style: .destructive, handler: { _ in

            }))
            present(alert, animated: true)
            return
        }
        loadCrossword(url: url)
    }

    func loadCrossword(url: URL) {
        crosswordLoader.load(url: url) { horizontalDefs, verticalDefs, solution, colors in
            DispatchQueue.main.async {
                let resolvingViewController = ResolvingViewController(
                    url: url,
                    horizontalDefs: horizontalDefs,
                    verticalDefs: verticalDefs,
                    solution: solution,
                    colors: colors
                )

                resolvingViewController.delegate = self

                self.showVC(resolvingViewController)
            }
        } failure: {
        }
    }

    var storage: Storage = Storage()

    func resolvingViewController(
        _ vc: ResolvingViewController,
        didChangeState field: Field,
        layers: [String : Field],
        currentLayer: String?,
        solution: [[Int]],
        colors: [Field.Color],
        url: URL
    ) {
        storage.save(
            key: url.absoluteString,
            field: field,
            layers: layers,
            currentLayer: currentLayer,
            solution: solution,
            colors: colors
        )
    }

    func resolvingViewControllerDidTapExit(_: ResolvingViewController) {
        let listVC = ListViewController()
        listVC.delegate = self

        showVC(listVC)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let listVC = ListViewController()
        listVC.delegate = self

        showVC(listVC)
    }

    func showVC(_ vc: UIViewController) {
        if let currentViewController = currentViewController {
            currentViewController.willMove(toParent: nil)
            currentViewController.view.removeFromSuperview()
            currentViewController.removeFromParent()
        }

        currentViewController = vc

        addChild(vc)
        view.addSubview(vc.view)
        vc.didMove(toParent: self)

        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: view.topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

}
