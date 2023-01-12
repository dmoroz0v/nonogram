//
//  MenuView.swift
//  nonogram
//
//  Created by Denis S. Morozov on 12.01.2023.
//

import Foundation
import UIKit

protocol MenuViewDelegate: AnyObject {
    func menuViewPresentingViewController(_: MenuView) -> UIViewController
    func menuView(_: MenuView, didSelectPen: Pen)
}

class MenuView: UIView {

    weak var delegate: MenuViewDelegate?

    private let empty = UIButton()
    private let color = UIButton()
    private let layerB = UIButton()

    var pen: Pen = .empty {
        didSet {
            update()
        }
    }

    private func update() {
        empty.backgroundColor = .clear
        color.backgroundColor = .clear
        layerB.backgroundColor = .clear

        switch pen {
        case .empty:
            empty.backgroundColor = .gray
        case .color(let c):
            color.backgroundColor = c.c
        case .layer(let c):
            layerB.backgroundColor = c.c
        }
    }

    var colors: [Field.Color] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        empty.setTitle("E", for: .normal)
        empty.setTitleColor(.black, for: .normal)
        empty.addTarget(self, action: #selector(tapEmpty), for: .touchUpInside)
        stackView.addArrangedSubview(empty)

        color.setTitle("C", for: .normal)
        color.addTarget(self, action: #selector(tapColor), for: .touchUpInside)
        color.setTitleColor(.black, for: .normal)
        stackView.addArrangedSubview(color)

        layerB.setTitle("L", for: .normal)
        layerB.addTarget(self, action: #selector(tapLayer), for: .touchUpInside)
        layerB.setTitleColor(.black, for: .normal)
        stackView.addArrangedSubview(layerB)

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        update()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class SelectColorViewController: UIViewController {

        var colors: [Field.Color] = []

        var didSelect: ((_ index: Int) -> Void)?

        override func loadView() {
            view = UIStackView()
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            let stackView = view as! UIStackView
            stackView.axis = .vertical

            for color in colors {
                let v = UIView()
                v.backgroundColor = color.c
                stackView.addArrangedSubview(v)

                let tapGR = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
                v.addGestureRecognizer(tapGR)

                NSLayoutConstraint.activate([
                    v.widthAnchor.constraint(equalToConstant: 50),
                    v.heightAnchor.constraint(equalToConstant: 50),
                ])
            }

            preferredContentSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        }

        @objc private func didTap(_ tapGR: UITapGestureRecognizer) {
            let i = ((view as! UIStackView).arrangedSubviews.firstIndex(where: { $0 === tapGR.view }))!
            didSelect?(i)
        }
    }

    @objc private func tapEmpty() {
        delegate?.menuView(self, didSelectPen: .empty)
    }

    var popoverContentController: SelectColorViewController?
    @objc private func tapColor() {
        let popoverContentController = SelectColorViewController()
        self.popoverContentController = popoverContentController
        popoverContentController.colors = colors
        popoverContentController.modalPresentationStyle = .popover
        popoverContentController.didSelect = { [weak self] i in
            self?.popoverContentController?.dismiss(animated: true)
            self?.popoverContentController = nil
            self?.delegate?.menuView(self!, didSelectPen: .color(self!.colors[i]))
        }

        if let popoverPresentationController = popoverContentController.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .right
            popoverPresentationController.sourceView = self
            popoverPresentationController.sourceRect = color.frame

            let presentingViewController = delegate?.menuViewPresentingViewController(self)
            presentingViewController?.present(popoverContentController, animated: true, completion: nil)
        }
    }

    @objc private func tapLayer() {
        let popoverContentController = SelectColorViewController()
        self.popoverContentController = popoverContentController
        popoverContentController.colors = colors
        popoverContentController.modalPresentationStyle = .popover
        popoverContentController.didSelect = { [weak self] i in
            self?.popoverContentController?.dismiss(animated: true)
            self?.popoverContentController = nil
            self?.delegate?.menuView(self!, didSelectPen: .layer(self!.colors[i]))
        }

        if let popoverPresentationController = popoverContentController.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .right
            popoverPresentationController.sourceView = self
            popoverPresentationController.sourceRect = layerB.frame

            let presentingViewController = delegate?.menuViewPresentingViewController(self)
            presentingViewController?.present(popoverContentController, animated: true, completion: nil)
        }
    }
}
