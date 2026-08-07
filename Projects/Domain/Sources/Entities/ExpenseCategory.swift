//
//  ExpenseCategory.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 8/6/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation

public struct ExpenseCategory: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var symbolName: String
    public var colorToken: String
    public var sortOrder: Int
    public let isBuiltIn: Bool
    
    public init(id: UUID = UUID(), name: String, symbolName: String, colorToken: String, sortOrder: Int = 0, isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.colorToken = colorToken
        self.sortOrder = sortOrder
        self.isBuiltIn = isBuiltIn
    }
}
