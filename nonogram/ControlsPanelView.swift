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
    func controlsPanelViewDidTapCloseLayer(_: ControlsPanelView)
    func controlsPanelView(_: ControlsPanelView, didTapLayers: UIView)
    func controlsPanelView(_: ControlsPanelView, didTapColors: UIView)
}

final class ControlsPanelView: UIView {

    final class EmptyView: UIView {
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

    private let exitButton = UIButton()
    private let colorsButton = ColorButton()
    private let layersButton = UIButton()
    private let closeLayerButton = UIButton()

    func update(with pen: Pen) {
        switch pen {
        case .empty:
            colorsButton.backgroundColor = nil
        case .color(let c):
            colorsButton.backgroundColor = c.c
        }
    }

    func showDefaultState() {
        showButtons([exitButton, colorsButton, layersButton])
    }

    func showLayerState() {
        showButtons([exitButton, colorsButton, closeLayerButton])
    }

    private func showButtons(_ buttons: [UIView]) {
        if stackView.arrangedSubviews == buttons {
            return
        }

        stackView.arrangedSubviews.forEach({
            $0.removeFromSuperview()
        })

        buttons.forEach {
            stackView.addArrangedSubview($0)
        }
    }

    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .white
        layer.cornerRadius = 4
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 16
        layer.shadowOpacity = 0.2

        let pupochkaView = UIView()
        pupochkaView.translatesAutoresizingMaskIntoConstraints = false
        pupochkaView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        pupochkaView.layer.cornerRadius = 4
        pupochkaView.layer.masksToBounds = true
        addSubview(pupochkaView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 3

        exitButton.setImage(UIImage(named: "exit"), for: .normal)
        exitButton.addTarget(self, action: #selector(tapExit), for: .touchUpInside)
        stackView.addArrangedSubview(exitButton)

        colorsButton.addTarget(self, action: #selector(tapColors), for: .touchUpInside)
        stackView.addArrangedSubview(colorsButton)

        layersButton.setImage(UIImage(named: "layers"), for: .normal)
        layersButton.addTarget(self, action: #selector(tapLayers), for: .touchUpInside)
        stackView.addArrangedSubview(layersButton)

        closeLayerButton.setTitle("X", for: .normal)
        closeLayerButton.addTarget(self, action: #selector(tapCloseLayer), for: .touchUpInside)
        closeLayerButton.setTitleColor(.black, for: .normal)

        addSubview(stackView)

        var constraints = [closeLayerButton, layersButton, exitButton, colorsButton].flatMap {
            [
                $0.widthAnchor.constraint(equalToConstant: 32),
                $0.heightAnchor.constraint(equalToConstant: 32),
            ]
        }

        constraints += [
            pupochkaView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            pupochkaView.heightAnchor.constraint(equalToConstant: 6),
            pupochkaView.widthAnchor.constraint(equalToConstant: 24),
            pupochkaView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.topAnchor.constraint(equalTo: pupochkaView.bottomAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapExit() {
        delegate?.controlsPanelViewDidTapExit(self)
    }

    @objc private func tapCloseLayer() {
        delegate?.controlsPanelViewDidTapCloseLayer(self)
    }

    @objc private func tapColors() {
        delegate?.controlsPanelView(self, didTapColors: colorsButton)
    }

    @objc private func tapLayers() {
        delegate?.controlsPanelView(self, didTapLayers: layersButton)
    }
}
