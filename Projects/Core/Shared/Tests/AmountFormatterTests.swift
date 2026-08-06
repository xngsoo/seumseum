//
//  AmountFormatterTests.swift
//  Shared
//
//  Created by SEUNGSOO HAN on 8/6/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import Testing
import Shared

@Suite("AmountFormatter")
struct AmountFormatterTests {

    @Test("축약 표기", arguments: [
        (Decimal(0),   "0원"),
        (9_800,        "9800원"),        // 함정 3 — 0.9만원으로 새면 실패
        (9_999,        "9999원"),
        (10_000,       "1만원"),
        (112_500,      "11.2만원"),      // 버림 — 반올림이면 11.3만원
        (1_535_000,    "153.5만원"),
        (99_995_000,   "9999.5만원"),
        (99_999_500,   "9999.9만원"),    // 버림이 단위를 못 넘김
        (100_000_000,  "1억원"),
        (120_000_000,  "1.2억원"),
    ])
    func short(amount: Decimal, expected: String) {
        #expect(AmountFormatter.short(amount) == expected)
    }

    @Test("원 단위 표기", arguments: [
        (Decimal(1_535_000), "1,535,000원"),
        (9_800,              "9,800원"),
        (120_000_000,        "120,000,000원"),
    ])
    func full(amount: Decimal, expected: String) {
        #expect(AmountFormatter.full(amount) == expected)
    }
}
