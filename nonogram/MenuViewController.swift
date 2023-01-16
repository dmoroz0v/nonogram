//
//  MenuViewController.swift
//  nonogram
//
//  Created by Denis S. Morozov on 16.01.2023.
//

import Foundation
import UIKit

protocol MenuViewControllerDelegate: AnyObject {
    func menuViewController(_: MenuViewController, load: URL)
    func menuViewControllerContinue(_: MenuViewController)
}

class MenuViewController: UIViewController {

    weak var delegate: MenuViewControllerDelegate?

    let textField = UITextField()
    let loadButton = UIButton()
    let continueButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        textField.translatesAutoresizingMaskIntoConstraints = false
        loadButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false

        textField.backgroundColor = .lightGray

        view.addSubview(textField)
        view.addSubview(loadButton)
        view.addSubview(continueButton)

        loadButton.addTarget(self, action: #selector(tapLoad), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(tapContinue), for: .touchUpInside)

        loadButton.setTitle("Загрузить", for: .normal)
        loadButton.setTitleColor(.black, for: .normal)
        continueButton.setTitle("Продолжить", for: .normal)
        continueButton.setTitleColor(.black, for: .normal)

        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.topAnchor, constant: 200),
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.widthAnchor.constraint(equalToConstant: 400),

            loadButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 50),
            loadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            continueButton.topAnchor.constraint(equalTo: loadButton.bottomAnchor, constant: 50),
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    @objc private func tapLoad() {
        if let url = URL(string: textField.text ?? "") {
            delegate?.menuViewController(self, load: url)
        }
    }

    @objc private func tapContinue() {
        delegate?.menuViewControllerContinue(self)
    }
}
