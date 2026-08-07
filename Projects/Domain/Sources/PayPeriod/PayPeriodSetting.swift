//
//  PayPeriodSetting.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation

public enum PayPeriodSetting: Hashable, Sendable {
    case calendarMonth
    case payday(dayOfMonth: Int, adjustment: PaydayAdjustment)
    
    public static let `default`: PayPeriodSetting = .calendarMonth
}
