//
//  Bound.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 02.06.2021.
//

import Foundation

class Bound<T> {
    typealias Listener = (T) -> Void
    private var listeners: [Listener] = []
    
    var value: T {
        didSet {
            listeners.forEach { $0(value) }
        }
    }

    init(_ value: T) {
        self.value = value
    }
    
    func bind(listener: Listener?) {
        guard let listener = listener else {
            return
        }
        self.listeners.append(listener)
    }
}
