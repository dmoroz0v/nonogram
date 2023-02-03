//
//  ViewController.swift
//  nonogram
//
//  Created by Denis S. Morozov on 12.01.2023.
//

import UIKit

class ViewController: UIViewController, ResolvingViewControllerDelegate, ListViewControllerDelegate {

    private var currentViewController: UIViewController?
    private lazy var listViewController = ListViewController()
    private let crosswordLoader = CrosswordLoader()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

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
            alert.addAction(.init(title: "Отмена", style: .destructive))
            present(alert, animated: true)
            return
        }
        loadCrossword(url: url)
    }

    func loadCrossword(url: URL) {
        view.bringSubviewToFront(activityIndicator)
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        view.alpha = 0.5
        crosswordLoader.load(url: url) { horizontalDefs, verticalDefs, solution, colors in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.view.isUserInteractionEnabled = true
                self.view.alpha = 1

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
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.view.isUserInteractionEnabled = true
                self.view.alpha = 1
            }
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
        showVC(listViewController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        listViewController.delegate = self
        showVC(listViewController)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
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
