//
//  ViewController.swift
//  nonogram
//
//  Created by Denis S. Morozov on 12.01.2023.
//

import UIKit


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let resolvingViewController = ResolvingViewController()
        addChild(resolvingViewController)
        view.addSubview(resolvingViewController.view)
        resolvingViewController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            resolvingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            resolvingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            resolvingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resolvingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

}
