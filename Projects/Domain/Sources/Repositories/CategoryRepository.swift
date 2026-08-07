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
    func delete(id: UUID) async throws
    func reorder(_ orderedIDs: [UUID]) async throws
}
