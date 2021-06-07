//
//  USVPickerView.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 07.06.2021.
//

import UIKit

protocol USVPickerViewDelegate: AnyObject {
    func pickerDidSelectLowLight()
    func pickerDidSelectMediumLight()
    func pickerDidSelectHighLight()
}

class USVPickerView: UIView {
    private lazy var lowButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitle("Low Light", for: .normal)
        button.addTarget(self, action: #selector(lowButtonPressed), for: .touchUpInside)
        return button
    }()
    
    private lazy var mediumButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitle("Medium Light", for: .normal)
        button.addTarget(self, action: #selector(mediumButtonPressed), for: .touchUpInside)
        return button
    }()
    
    private lazy var highButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitle("High Light", for: .normal)
        button.addTarget(self, action: #selector(highButtonPressed), for: .touchUpInside)
        return button
    }()
    
    weak var delegate: USVPickerViewDelegate?
    
    @objc private func lowButtonPressed() {
        delegate?.pickerDidSelectLowLight()
    }
    
    @objc private func mediumButtonPressed() {
        delegate?.pickerDidSelectMediumLight()
    }
    
    @objc private func highButtonPressed() {
        delegate?.pickerDidSelectHighLight()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        let container = UIStackView(arrangedSubviews: [lowButton, mediumButton, highButton])
        container.axis = .horizontal
        container.distribution = .equalSpacing
        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
        container.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
        container.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
    }
}
