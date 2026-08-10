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

/// 어떤 편집 화면을 열지. Feature 끼리 직접 의존하지 않기 위해 이곳을 경유
public enum EditorRoute: Hashable, Sendable, Identifiable {
    case create(day: Date)
    case edit(Expense)
    
    public var id: String {
        switch self {
        case let .create(day):
            "create-\(day.timeIntervalSince1970)"
        case let .edit(expense):
            "edit-\(expense.id.uuidString)"
        }
    }
}

/// 탭 간 연동의 통로
@MainActor
@Observable
public final class AppNavigation {
    public var selectedTab: AppTab
    public var selectedDate: Date
    public var editorRoute: EditorRoute?
    
    /// 데이터가 바뀔 때마다 증가
    public private(set) var dataVersion: Int = 0
    
    public init(tab: AppTab = .daily, date: Date = CalendarDay.today()) {
        self.selectedTab = tab
        self.selectedDate = date
    }
    
    /// 특정 날짜의 일별 화면으로 이동
    public func showDaily(_ day: Date) {
        selectedDate = day
        selectedTab = .daily
    }
    
    /// 추가 화면을 열기. 탭 1에서는 보고 있는 날짜, 그 외엔 오늘 날짜
    public func presentCreateEditor() {
        let day = selectedTab == .daily ? selectedDate : CalendarDay.today()
        editorRoute = .create(day: day)
    }
    
    public func presentEditor(for expense: Expense) {
        editorRoute = .edit(expense)
    }
    
    public func dataDidChange() {
        dataVersion &+= 1
    }
}
