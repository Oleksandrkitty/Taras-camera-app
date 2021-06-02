//
//  NibInstantiatable.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 02.06.2021.
//

import UIKit

protocol NibInstantiatable {}

extension UIView: NibInstantiatable {}

extension UIView {
    class var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
}

extension NibInstantiatable where Self: UIView {
    static func instantiate() -> Self {
        return self.nib.instantiate(withOwner: nil, options: nil).first as! Self
    }
}
