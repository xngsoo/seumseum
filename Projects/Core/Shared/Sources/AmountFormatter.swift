//
//  AmountFormatter.swift
//  Shared
//
//  Created by SEUNGSOO HAN on 8/6/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation

public enum AmountFormatter {
    
    // MARK: - Public
    
    public static func short(_ amount: Decimal) -> String {
        let (value, unit) = scaled(amount)
        return shortStyle.format(value) + unit + "원"
    }
    
    public static func full(_ amount: Decimal) -> String {
        return fullStyle.format(amount) + "원"
    }
    
    // MARK: - Private
    
    private static let locale = Locale(identifier: "ko_KR")
    
    private static let shortStyle = Decimal.FormatStyle.number
        .precision(.fractionLength(0...1))
        .rounded(rule: .towardZero)
        .grouping(.never)
        .locale(locale)
    
    private static let fullStyle = Decimal.FormatStyle.number
        .precision(.fractionLength(0))
        .locale(locale)
    
    /// 크기를 판정한 뒤 환산
    private static func scaled(_ amount: Decimal)
    -> (value: Decimal, unit: String) {
        switch amount {
        case 100_000_000...:
            (amount / 100_000_000, "억")
        case 10_000...:
            (amount / 10_000, "만")
        default:
            (amount, "")
        }
    }
}
