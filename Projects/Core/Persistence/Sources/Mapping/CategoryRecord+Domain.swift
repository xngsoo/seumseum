//
//  CategoryRecord+Domain.swift
//  Persistence
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import Domain
import Shared

extension CategoryRecord {
    convenience init(_ category: ExpenseCategory) {
        self.init(
            id: category.id,
            name: category.name,
            symbolName: category.symbolName,
            colorToken: category.colorToken.rawValue,
            sortOrder: category.sortOrder,
            isBuiltIn: category.isBuiltIn
        )
    }

    var domain: ExpenseCategory {
        ExpenseCategory(
            id: id,
            name: name,
            symbolName: symbolName,
            colorToken: ColorToken(rawValue: colorToken) ?? .gray,
            sortOrder: sortOrder,
            isBuiltIn: isBuiltIn
        )
    }

    /// `id`·`isBuiltIn`은 바꾸지 않는다. `sortOrder`는 저장소가 따로 정한다.
    func apply(_ category: ExpenseCategory) {
        name = category.name
        symbolName = category.symbolName
        colorToken = category.colorToken.rawValue
    }
}
