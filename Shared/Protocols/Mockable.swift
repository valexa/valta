//
//  Mockable.swift
//  valta
//
//  Created by vlad on 11/12/2025.
//

import Foundation

protocol Mockable {
    static func mock() -> Self
}

extension Mockable {
    static var mock: Self {
        mock()
    }
}
