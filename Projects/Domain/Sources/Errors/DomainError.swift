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
    case categoryInUse(UUID)
    case builtInCategoryNotDeletable(UUID)
    case invalidAmount(Decimal)
    case invalidIndex(Int)
    case storageFailed(String)
}

extension DomainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .expenseNotFound: "지출 항목을 찾을 수 없습니다."
        case .categoryNotFound: "카테고리를 찾을 수 없습니다."
        case .categoryInUse: "이 카테고리를 사용하는 지출이 있어 삭제할 수 없습니다."
        case .builtInCategoryNotDeletable: "기본 카테고리는 삭제할 수 없습니다."
        case .invalidAmount: "금액은 0보다 커야 합니다."
        case .invalidIndex: "잘못된 위치입니다."
        case .storageFailed: "저장소에 접근하지 못했습니다."
        }
    }
}
