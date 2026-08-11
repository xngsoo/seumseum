//
//  CategoryRepository.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation

public protocol CategoryRepository: Sendable {
    func categories() async throws -> [ExpenseCategory]
    func category(id: UUID) async throws -> ExpenseCategory?
    func insert(_ category: ExpenseCategory, at index: Int) async throws
    func update(_ category: ExpenseCategory) async throws
    /// 이 카테고리를 쓰는 지출 건수. 삭제 전에 무엇이 함께 지워지는지 알리는 데 쓴다.
    func expenseCount(using id: UUID) async throws -> Int
    /// 카테고리와 그 카테고리를 쓰는 지출을 함께 지운다.
    func delete(id: UUID) async throws
    func reorder(_ orderedIDs: [UUID]) async throws
}
