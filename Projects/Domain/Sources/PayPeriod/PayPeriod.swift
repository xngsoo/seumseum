//
//  PayPeriod.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import Shared

public struct PayPeriod: Hashable, Sendable {
    public let start: Date
    public let end: Date
    
    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
    
    public var range: Range<Date> { start ..< end }
    public var lastDay: Date { CalendarDay.adding(days: -1, to: end) }
    
    public func contains(_ day: Date) -> Bool { range.contains(day) }
}
