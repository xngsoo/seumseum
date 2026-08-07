//
//  BuiltInCategories.swift
//  Persistence
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import Domain

public enum BuiltInCategories {
    public static let all: [ExpenseCategory] = [
        .init(name: "식비", symbolName: "fork.knife", colorToken: .orange, sortOrder: 0, isBuiltIn: true),
        .init(name: "카페·간식", symbolName: "cup.and.saucer.fill", colorToken: .brown, sortOrder: 1, isBuiltIn: true),
        .init(name: "교통", symbolName: "bus.fill", colorToken: .blue, sortOrder: 2, isBuiltIn: true),
        .init(name: "쇼핑", symbolName: "bag.fill", colorToken: .pink, sortOrder: 3, isBuiltIn: true),
        .init(name: "생활", symbolName: "house.fill", colorToken: .green, sortOrder: 4, isBuiltIn: true),
        .init(name: "의료·건강", symbolName: "cross.case.fill", colorToken: .red, sortOrder: 5, isBuiltIn: true),
        .init(name: "문화·여가", symbolName: "ticket.fill", colorToken: .purple, sortOrder: 6, isBuiltIn: true),
        .init(name: "기타", symbolName: "ellipsis.circle.fill", colorToken: .gray, sortOrder: 7, isBuiltIn: true),
    ]
}
