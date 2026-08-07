//
//  CategoryRepository.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation

public protocol CategoryRepository: Sendable {
    func categories() async throws -> [Category]
    func category(id: UUID) async throws -> Category?
    func insert(_ category: Category, at index: Int) async throws
    func update(_ category: Category) async throws
    func delete(id: UUID) async throws
    func reorder(_ orderedIDs: [UUID]) async throws
}
