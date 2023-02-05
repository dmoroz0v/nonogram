//
//  ControlsPanelViewController.swift
//  nonogram
//
//  Created by Denis S. Morozov on 05.02.2023.
//

import Foundation
import UIKit

protocol ControlsPanelViewControllerDelegate: AnyObject {
    func controlsPanelViewControllerDidTapExit(_: ControlsPanelViewController)
    func controlsPanelViewController(_: ControlsPanelViewController, didSelectPen: Pen)
    func controlsPanelViewController(_: ControlsPanelViewController, didSelectLayerColor: Field.Color)
    func controlsPanelViewControllerDidTapCloseLayer(_: ControlsPanelViewController)
}

final class ControlsPanelViewController: UIViewController {

    private final class SelectPenViewController: UIViewController {

        var pens: [Pen] = []

        var didSelectPen: ((_ pen: Pen) -> Void)?

        private let stackView = UIStackView()

        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .lightGray

            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical

            view.addSubview(stackView)

            let itemAspectSize: CGFloat = 50

            for pen in pens {
                let v: UIView!
                switch pen {
                case .empty:
                    v = ControlsPanelView.EmptyView(dotRadius: 3)
                case .color(let color):
                    v = UIView()
                    v.backgroundColor = color.c
                }
                stackView.addArrangedSubview(v)

                let tapGR = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
                v.addGestureRecognizer(tapGR)

                NSLayoutConstraint.activate([
                    v.heightAnchor.constraint(equalToConstant: itemAspectSize),
                    v.widthAnchor.constraint(equalToConstant: itemAspectSize),
                ])
            }

            preferredContentSize = CGSize(width: itemAspectSize, height: CGFloat(pens.count) * itemAspectSize)
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()

            var frame = CGRect(origin: .zero, size: preferredContentSize)
            if popoverPresentationController?.arrowDirection == .left {
                frame.origin.x = view.frame.width - preferredContentSize.width
            } else if popoverPresentationController?.arrowDirection == .up {
                frame.origin.y = view.frame.height - preferredContentSize.height
            }
            stackView.frame = frame
        }

        @objc private func didTap(_ tapGR: UITapGestureRecognizer) {
            let i = (stackView.arrangedSubviews.firstIndex(where: { $0 === tapGR.view }))!
            didSelectPen?(pens[i])
        }
    }

    weak var delegate: ControlsPanelViewControllerDelegate?

    var colors: [Field.Color] = []
    var pen: Pen = .empty {
        didSet {
            update()
        }
    }

    var selectedLayerColor: Field.Color? {
        didSet {
            update()
        }
    }

    private lazy var controlsPanelView = ControlsPanelView()
    private var popoverContentController: SelectPenViewController?

    override func loadView() {
        view = controlsPanelView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        controlsPanelView.delegate = self
        update()
    }

    func update() {
        guard isViewLoaded else {
            return
        }

        if selectedLayerColor != nil {
            controlsPanelView.showLayerState()
        } else {
            controlsPanelView.showDefaultState()
        }

        controlsPanelView.update(with: pen)
    }

}

extension ControlsPanelViewController: ControlsPanelViewDelegate {

    func controlsPanelViewDidTapExit(_: ControlsPanelView) {
        delegate?.controlsPanelViewControllerDidTapExit(self)
    }

    func controlsPanelViewDidTapCloseLayer(_: ControlsPanelView) {
        delegate?.controlsPanelViewControllerDidTapCloseLayer(self)
    }

    func controlsPanelView(_: ControlsPanelView, didTapColors colorsView: UIView) {
        let popoverContentController = SelectPenViewController()
        self.popoverContentController = popoverContentController
        if let selectedLayerColor {
            popoverContentController.pens = [.empty, .color(selectedLayerColor)]
        } else {
            popoverContentController.pens = [.empty] + colors.map({ .color($0) })
        }
        popoverContentController.modalPresentationStyle = .popover
        popoverContentController.didSelectPen = { [weak self] pen in
            guard let self else {
                return
            }
            self.popoverContentController?.dismiss(animated: true)
            self.popoverContentController = nil
            self.delegate?.controlsPanelViewController(self, didSelectPen: pen)
        }

        if let popoverPresentationController = popoverContentController.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .any
            popoverPresentationController.sourceView = colorsView

            present(popoverContentController, animated: true, completion: nil)
        }
    }

    func controlsPanelView(_: ControlsPanelView, didTapLayers layersView: UIView) {
        let popoverContentController = SelectPenViewController()
        self.popoverContentController = popoverContentController
        popoverContentController.pens = colors.map({ .color($0) })
        popoverContentController.modalPresentationStyle = .popover
        popoverContentController.didSelectPen = { [weak self] pen in
            guard let self else {
                return
            }
            self.popoverContentController?.dismiss(animated: true)
            self.popoverContentController = nil
            if case .color(let c) = pen {
                self.delegate?.controlsPanelViewController(self, didSelectLayerColor: c)
            }
        }

        if let popoverPresentationController = popoverContentController.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .any
            popoverPresentationController.sourceView = layersView

            present(popoverContentController, animated: true, completion: nil)
        }
    }

}
