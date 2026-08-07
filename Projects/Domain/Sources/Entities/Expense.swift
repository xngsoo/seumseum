//
//  Expense.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 8/6/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import Shared

public struct Expense: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var amount: Decimal
    public var memo: String
    public var categoryID: UUID
    public var date: Date
    public let createdAt: Date
    public var sortOrder: Int
    
    public init(id: UUID = UUID(), amount: Decimal, memo: String = "", categoryID: UUID, date: Date, createdAt: Date = .now, sortOrder: Int = 0) {
        self.id = id
        self.amount = amount
        self.memo = memo
        self.categoryID = categoryID
        self.date = date
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}

public extension Expense {
    /// 사용자 입력으로 새 소비를 생성.
    /// sortOrer는 저장소가 위치에 맞춰 다시 설정.
    static func make(
        amount: Decimal,
        memo: String = "",
        categoryID: UUID,
        pickedDate: Date,
        timeZone: TimeZone = .current,
        now: Date = .now
    ) -> Expense {
        Expense(
            amount: amount,
            memo: memo,
            categoryID: categoryID,
            date: CalendarDay.normalized(pickedDate, in: timeZone),
            createdAt: now,
            sortOrder: 0
        )
    }
    
    /// 사용자가 선택한 날짜로 정규화 후 이동
    mutating func move(to pickedDate: Date, in timeZone: TimeZone = .current) {
        date = CalendarDay.normalized(pickedDate, in: timeZone)
    }
}
