//
//  PersistenceSchema.swift
//  Persistence
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import SwiftData

enum PersistenceSchema {
    static let models: [any PersistentModel.Type] = [
        ExpenseRecord.self,
        CategoryRecord.self,
    ]

    static func container(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema(models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
