//
//  ViewController.swift
//  nonogram
//
//  Created by Denis S. Morozov on 12.01.2023.
//

import UIKit

final class ViewController: UIViewController, ResolvingViewControllerDelegate, PagesViewControllerDelegate {

    private var currentViewController: UIViewController?
    private let crosswordLoader = CrosswordLoader()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    func pagesViewController( _: PagesViewController, didSelectItem item: ListItem, savedData: Storage.Data?) {
        if let data = savedData {
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
        } else {
            loadCrossword(url: item.url, thumbnailUrl: item.thumbnailUrl, title: item.title)
        }
    }

    func loadCrossword(url: URL, thumbnailUrl: URL, title: String) {
        view.bringSubviewToFront(activityIndicator)
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        view.alpha = 0.5
        crosswordLoader.load(url: url) { horizontalLinesHunks, verticalLinesHunks, solution, colors in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.view.isUserInteractionEnabled = true
                self.view.alpha = 1

                let resolvingViewController = ResolvingViewController(
                    url: url,
                    thumbnailUrl: thumbnailUrl,
                    title: title,
                    horizontalLinesHunks: horizontalLinesHunks,
                    verticalLinesHunks: verticalLinesHunks,
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
        let pagesViewController = PagesViewController(storage: storage)
        pagesViewController.delegate = self
        showVC(pagesViewController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let pagesViewController = PagesViewController(storage: storage)
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
