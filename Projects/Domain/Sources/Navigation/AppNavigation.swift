//
//  AppNavigation.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import Observation
import Shared

public enum AppTab: Hashable, Sendable, CaseIterable {
    case daily, monthly, statistics, settings
}

/// 탭 간 연동의 통로
@MainActor
@Observable
public final class AppNavigation {
    public var selectedTab: AppTab
    public var selectedDate: Date
    
    public init(tab: AppTab = .daily, date: Date = CalendarDay.today()) {
        self.selectedTab = tab
        self.selectedDate = date
    }
    
    /// 특정 날짜의 일별 화면으로 이동
    public func showDaily(_ day: Date) {
        selectedDate = day
        selectedTab = .daily
    }
}
