//
//  ExpenseRecord.swift
//  Persistence
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class ExpenseRecord {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var memo: String
    var categoryID: UUID
    var day: Date
    var createdAt: Date
    var sortOrder: Int
    
    init(
        id: UUID, amount: Decimal, memo: String, categoryID: UUID,
        day: Date, createdAt: Date, sortOrder: Int
    ) {
        self.id = id
        self.amount = amount
        self.memo = memo
        self.categoryID = categoryID
        self.day = day
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}
