//
//  ExpenseRepository.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 8/6/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation

public protocol ExpenseRepository: Sendable {
    func expenses(on day: Date) async throws -> [Expense]
    func expenses(in range: Range<Date>) async throws -> [Expense]
    func insert(_ expense: Expense, at index: Int) async throws
    func update(_ expense: Expense) async throws
    
    @discardableResult
    func delete(id: UUID) async throws -> Int
    func reorder(_ orderedIDs: [UUID], on day: Date) async throws
}
