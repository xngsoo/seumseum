//
//  DomainError.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation

public enum DomainError: Error, Equatable, Sendable {
    case expenseNotFound(UUID)
    case categoryNotFound(UUID)
    case categoryLimitReached(max: Int)
    case lastCategoryNotDeletable
    case invalidAmount(Decimal)
    case invalidIndex(Int)
    case storageFailed(String)
}

extension DomainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .expenseNotFound: "지출 항목을 찾을 수 없습니다."
        case .categoryNotFound: "카테고리를 찾을 수 없습니다."
        case .lastCategoryNotDeletable: "카테고리는 하나 이상 있어야 합니다."
        case .invalidAmount: "금액은 0보다 커야 합니다."
        case .invalidIndex: "잘못된 위치입니다."
        case .storageFailed: "저장소에 접근하지 못했습니다."
        case .categoryLimitReached(max: let max):
            "카테고리는 최대 \(max)개까지 만들 수 있습니다."
        }
    }
}
