//
//  ExpenseRecord+Domain.swift
//  Persistence
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import Domain

extension ExpenseRecord {
    convenience init(_ expense: Expense) {
        self.init(
            id: expense.id,
            amount: expense.amount,
            memo: expense.memo,
            categoryID: expense.categoryID,
            day: expense.date,
            createdAt: expense.createdAt,
            sortOrder: expense.sortOrder
        )
    }

    var domain: Expense {
        Expense(
            id: id,
            amount: amount,
            memo: memo,
            categoryID: categoryID,
            date: day,
            createdAt: createdAt,
            sortOrder: sortOrder
        )
    }

    /// `id`·`createdAt`은 바꾸지 않는다. `sortOrder`는 저장소가 따로 정한다.
    func apply(_ expense: Expense) {
        amount = expense.amount
        memo = expense.memo
        categoryID = expense.categoryID
        day = expense.date
    }
}
