//
//  ControlsPanelView.swift
//  nonogram
//
//  Created by Denis S. Morozov on 12.01.2023.
//

import Foundation
import UIKit

protocol ControlsPanelViewDelegate: AnyObject {
    func controlsPanelViewDidTapExit(_: ControlsPanelView)
    func controlsPanelViewPresentingViewController(_: ControlsPanelView) -> UIViewController
    func controlsPanelView(_: ControlsPanelView, didSelectPen: Pen)
    func controlsPanelView(_: ControlsPanelView, didSelectLayerColor: Field.Color)
    func controlsPanelViewDidCloseLayer(_: ControlsPanelView)
}

final class ControlsPanelView: UIView {

    private final class EmptyView: UIView {
        init(dotRadius: CGFloat) {
            super.init(frame: .zero)

            backgroundColor = .white

            let dotView = UIView()
            dotView.translatesAutoresizingMaskIntoConstraints = false
            dotView.backgroundColor = .black
            dotView.layer.masksToBounds = true
            dotView.layer.cornerRadius = dotRadius

            addSubview(dotView)

            NSLayoutConstraint.activate([
                dotView.centerYAnchor.constraint(equalTo: centerYAnchor),
                dotView.centerXAnchor.constraint(equalTo: centerXAnchor),
                dotView.widthAnchor.constraint(equalToConstant: dotRadius * 2),
                dotView.heightAnchor.constraint(equalToConstant: dotRadius * 2),
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private final class ColorButton: UIControl {

        private let emptyView = EmptyView(dotRadius: 2)

        override var backgroundColor: UIColor? {
            didSet {
                emptyView.isHidden = (backgroundColor != nil)
            }
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            emptyView.translatesAutoresizingMaskIntoConstraints = false
            emptyView.isUserInteractionEnabled = false

            emptyView.layer.borderColor = UIColor.black.cgColor
            emptyView.layer.borderWidth = 1
            emptyView.layer.cornerRadius = 4

            layer.masksToBounds = true
            layer.cornerRadius = 4

            addSubview(emptyView)

            NSLayoutConstraint.activate([
                emptyView.topAnchor.constraint(equalTo: topAnchor),
                emptyView.bottomAnchor.constraint(equalTo: bottomAnchor),
                emptyView.leadingAnchor.constraint(equalTo: leadingAnchor),
                emptyView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    weak var delegate: ControlsPanelViewDelegate?

    private let exit = UIButton()
    private let color = ColorButton()
    private let layers = UIButton()
    private let close = UIButton()
    private var selectedLayerColor: Field.Color?

    var pen: Pen = .empty {
        didSet {
            update()
        }
    }

    private func update() {
        color.backgroundColor = .clear

        switch pen {
        case .empty:
            color.backgroundColor = nil
        case .color(let c):
            color.backgroundColor = c.c
        }
    }

    var colors: [Field.Color] = []

    func showCommon() {
        stackView.arrangedSubviews.forEach({
            $0.removeFromSuperview()
        })
        selectedLayerColor = nil

        stackView.addArrangedSubview(exit)
        stackView.addArrangedSubview(color)
        stackView.addArrangedSubview(layers)
    }

    func showLayer(color: Field.Color) {
        stackView.arrangedSubviews.forEach({
            $0.removeFromSuperview()
        })

        selectedLayerColor = color

        stackView.addArrangedSubview(exit)
        stackView.addArrangedSubview(self.color)
        stackView.addArrangedSubview(close)
    }

    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .white
        layer.cornerRadius = 4
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 16
        layer.shadowOpacity = 0.2

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4

        exit.setImage(UIImage(named: "exit"), for: .normal)
        exit.addTarget(self, action: #selector(tapExit), for: .touchUpInside)
        stackView.addArrangedSubview(exit)

        color.addTarget(self, action: #selector(tapColor), for: .touchUpInside)
        stackView.addArrangedSubview(color)

        layers.setImage(UIImage(named: "layers"), for: .normal)
        layers.addTarget(self, action: #selector(tapLayer), for: .touchUpInside)
        stackView.addArrangedSubview(layers)

        close.setTitle("X", for: .normal)
        close.addTarget(self, action: #selector(tapClose), for: .touchUpInside)
        close.setTitleColor(.black, for: .normal)

        addSubview(stackView)

        var constraints = [close, layers, exit, color].flatMap {
            [
                $0.widthAnchor.constraint(equalToConstant: 32),
                $0.heightAnchor.constraint(equalToConstant: 32),
            ]
        }

        constraints += [
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ]

        NSLayoutConstraint.activate(constraints)

        update()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class SelectColorViewController: UIViewController {

        enum Item {
            case empty, color(Field.Color)
        }

        var items: [Item] = []

        var didSelect: ((_ index: Int) -> Void)?

        private let stackView = UIStackView()

        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .lightGray

            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical

            view.addSubview(stackView)

            let itemAspectSize: CGFloat = 50

            for item in items {
                let v: UIView!
                switch item {
                case .empty:
                    v = EmptyView(dotRadius: 3)
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

            preferredContentSize = CGSize(width: itemAspectSize, height: CGFloat(items.count) * itemAspectSize)
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
            didSelect?(i)
        }
    }

    @objc private func tapExit() {
        delegate?.controlsPanelViewDidTapExit(self)
    }

    @objc private func tapClose() {
        delegate?.controlsPanelViewDidCloseLayer(self)
    }

    var popoverContentController: SelectColorViewController?
    @objc private func tapColor() {
        let popoverContentController = SelectColorViewController()
        self.popoverContentController = popoverContentController
        if let selectedLayerColor {
            popoverContentController.items = [.empty, .color(selectedLayerColor)]
        } else {
            popoverContentController.items = [.empty] + colors.map({ .color($0) })
        }
        popoverContentController.modalPresentationStyle = .popover
        popoverContentController.didSelect = { [weak self] i in
            guard let self else {
                return
            }
            self.popoverContentController?.dismiss(animated: true)
            self.popoverContentController = nil
            if i == 0 {
                self.delegate?.controlsPanelView(self, didSelectPen: .empty)
            } else if let selectedLayerColor = self.selectedLayerColor {
                self.delegate?.controlsPanelView(self, didSelectPen: .color(selectedLayerColor))
            } else {
                self.delegate?.controlsPanelView(self, didSelectPen: .color(self.colors[i - 1]))
            }
        }

        if let popoverPresentationController = popoverContentController.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .any
            popoverPresentationController.sourceView = self.color

            let presentingViewController = delegate?.controlsPanelViewPresentingViewController(self)
            presentingViewController?.present(popoverContentController, animated: true, completion: nil)
        }
    }

    @objc private func tapLayer() {
        let popoverContentController = SelectColorViewController()
        self.popoverContentController = popoverContentController
        popoverContentController.items = colors.map({ .color($0) })
        popoverContentController.modalPresentationStyle = .popover
        popoverContentController.didSelect = { [weak self] i in
            guard let self else {
                return
            }
            self.popoverContentController?.dismiss(animated: true)
            self.popoverContentController = nil
            self.delegate?.controlsPanelView(self, didSelectLayerColor: self.colors[i])
        }

        if let popoverPresentationController = popoverContentController.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .any
            popoverPresentationController.sourceView = self.layers

            let presentingViewController = delegate?.controlsPanelViewPresentingViewController(self)
            presentingViewController?.present(popoverContentController, animated: true, completion: nil)
        }
    }
}
