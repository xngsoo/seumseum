//
//  BuiltInCategories.swift
//  Persistence
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import Domain

/// 처음 실행할 때 넣는 카테고리. 넓은 묶음 여섯 개로 시작하고
/// 나머지 자리(최대 `ExpenseCategory.maxCount`)는 사용자가 채운다.
public enum BuiltInCategories {
    public static let all: [ExpenseCategory] = [
        .init(name: "주거/생활", symbolName: "house.fill", colorToken: .green, sortOrder: 0, isBuiltIn: true),
        .init(name: "식비", symbolName: "fork.knife", colorToken: .orange, sortOrder: 1, isBuiltIn: true),
        .init(name: "교통/통신", symbolName: "bus.fill", colorToken: .blue, sortOrder: 2, isBuiltIn: true),
        .init(name: "쇼핑/여가", symbolName: "bag.fill", colorToken: .pink, sortOrder: 3, isBuiltIn: true),
        .init(name: "건강/가족", symbolName: "cross.case.fill", colorToken: .red, sortOrder: 4, isBuiltIn: true),
        .init(name: "기타", symbolName: "ellipsis.circle.fill", colorToken: .gray, sortOrder: 5, isBuiltIn: true),
    ]
}
