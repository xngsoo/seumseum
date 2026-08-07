//
//  MappingTests.swift
//  Persistence
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import SwiftData
import Testing
import Shared
import Domain
@testable import Persistence

@Suite("매핑")
struct MappingTests {

    @Test("Expense 왕복 변환에서 값이 보존된다")
    func expenseRoundTrip() throws {
        let original = Expense(
            amount: Decimal(string: "12345.67") ?? .zero,
            memo: "저녁",
            categoryID: UUID(),
            date: CalendarDay.today(),
            sortOrder: 3
        )
        let restored = ExpenseRecord(original).domain
        #expect(restored == original)
    }

    @Test("ExpenseCategory 왕복 변환에서 값이 보존된다")
    func categoryRoundTrip() {
        let original = ExpenseCategory(
            name: "식비", symbolName: "fork.knife",
            colorToken: .orange, sortOrder: 2, isBuiltIn: true
        )
        #expect(CategoryRecord(original).domain == original)
    }

    @Test("apply는 id와 createdAt을 바꾸지 않는다")
    func applyPreservesIdentity() throws {
        let record = ExpenseRecord(
            Expense(amount: 1_000, categoryID: UUID(), date: CalendarDay.today())
        )
        let originalID = record.id
        let originalCreatedAt = record.createdAt

        var edited = record.domain
        edited.amount = 2_000
        edited.memo = "수정됨"
        record.apply(edited)

        #expect(record.id == originalID)
        #expect(record.createdAt == originalCreatedAt)
        #expect(record.amount == 2_000)
        #expect(record.memo == "수정됨")
    }

    @Test("apply는 sortOrder를 바꾸지 않는다")
    func applyIgnoresSortOrder() {
        let record = ExpenseRecord(
            Expense(amount: 1_000, categoryID: UUID(), date: CalendarDay.today(), sortOrder: 5)
        )
        var edited = record.domain
        edited.sortOrder = 99
        record.apply(edited)
        #expect(record.sortOrder == 5)
    }

    @Test("인메모리 컨테이너에 저장하고 다시 읽는다")
    @MainActor
    func inMemoryStore() throws {
        let container = try PersistenceSchema.container(inMemory: true)
        let context = container.mainContext
        let day = CalendarDay.today()

        context.insert(ExpenseRecord(
            Expense(amount: 5_000, memo: "점심", categoryID: UUID(), date: day)
        ))
        try context.save()

        let fetched = try context.fetch(
            FetchDescriptor<ExpenseRecord>(predicate: #Predicate { $0.day == day })
        )
        #expect(fetched.count == 1)
        #expect(fetched.first?.memo == "점심")
    }

    @Test("기본 카테고리는 8개이고 모두 isBuiltIn")
    func builtInCategories() {
        #expect(BuiltInCategories.all.count == 8)
        let allBuiltIn = BuiltInCategories.all.allSatisfy { $0.isBuiltIn }
        #expect(allBuiltIn)
        #expect(BuiltInCategories.all.map(\.sortOrder) == Array(0 ..< 8))
    }
}
