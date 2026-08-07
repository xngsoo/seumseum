//
//  CategoryRecord.swift
//  Persistence
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class CategoryRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbolName: String
    var colorToken: String
    var sortOrder: Int
    var isBuiltIn: Bool

    init(
        id: UUID, name: String, symbolName: String,
        colorToken: String, sortOrder: Int, isBuiltIn: Bool
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.colorToken = colorToken
        self.sortOrder = sortOrder
        self.isBuiltIn = isBuiltIn
    }
}
