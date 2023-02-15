//
//  ViewController.swift
//  nonogram
//
//  Created by Denis S. Morozov on 12.01.2023.
//

import UIKit

class ViewController: UIViewController, ResolvingViewControllerDelegate, PagesViewControllerDelegate {

    private var currentViewController: UIViewController?
    private let crosswordLoader = CrosswordLoader()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    func pagesViewController( _: PagesViewController, didSelectItem item: ListItem) {
        if let data = storage.load(key: item.url.absoluteString) {
            let alert = UIAlertController(title: nil, message: "", preferredStyle: .alert)
            alert.addAction(.init(title: "Новая", style: .default, handler: { _ in
                self.loadCrossword(url: item.url, thumbnailUrl: item.thumbnailUrl, title: item.title)
            }))
            alert.addAction(.init(title: "Продолжить", style: .default, handler: { _ in
                let resolvingViewController = ResolvingViewController(
                    url: item.url,
                    thumbnailUrl: item.thumbnailUrl,
                    title: item.title,
                    field: data.field,
                    layers: data.layers,
                    selectedLayerColor: data.selectedLayerColor,
                    solution: data.solution,
                    colors: data.colors,
                    showsErrors: data.showsErrors
                )

                resolvingViewController.delegate = self

                self.showVC(resolvingViewController)
            }))
            alert.addAction(.init(title: "Отмена", style: .destructive))
            present(alert, animated: true)
            return
        }
        loadCrossword(url: item.url, thumbnailUrl: item.thumbnailUrl, title: item.title)
    }

    func loadCrossword(url: URL, thumbnailUrl: URL, title: String) {
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
                    thumbnailUrl: thumbnailUrl,
                    title: title,
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

    private let storage = Storage()

    func resolvingViewController(
        _ vc: ResolvingViewController,
        didChangeState field: Field,
        layers: [String : Field],
        selectedLayerColor: Field.Color?,
        solution: [[Int]],
        colors: [Field.Color],
        url: URL,
        thumbnailUrl: URL,
        title: String,
        showsErrors: Bool
    ) {
        storage.save(
            key: url.absoluteString,
            url: url,
            thumbnailUrl: thumbnailUrl,
            title: title,
            field: field,
            layers: layers,
            selectedLayerColor: selectedLayerColor,
            solution: solution,
            colors: colors,
            showsErrors: showsErrors
        )
    }

    func resolvingViewControllerDidTapExit(_: ResolvingViewController) {
        let pagesViewController = PagesViewController()
        pagesViewController.delegate = self
        showVC(pagesViewController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let pagesViewController = PagesViewController()
        pagesViewController.delegate = self
        showVC(pagesViewController)

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
