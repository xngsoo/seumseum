//
//  PaydayAdjustment.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation

public enum PaydayAdjustment: String, Hashable, Sendable, CaseIterable {
    case prevBusinessDay
    case nextBusinessDay
    case none
}
