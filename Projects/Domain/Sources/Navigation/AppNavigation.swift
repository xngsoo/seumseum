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

/// 방금 지운 기록. 취소 스낵바를 띄우는 쪽에 원래 자리까지 함께 넘긴다.
public struct DeletedExpense: Equatable, Sendable {
    public let expense: Expense
    public let index: Int

    public init(expense: Expense, index: Int) {
        self.expense = expense
        self.index = index
    }
}

/// 탭 간 연동의 통로
@MainActor
@Observable
public final class AppNavigation {
    public var selectedTab: AppTab
    public var selectedDate: Date
    public var editorRoute: EditorRoute?

    /// 수정 화면에서 지운 기록. 모달이 닫힌 뒤 목록 화면이 취소 스낵바를 띄운다.
    /// 삭제는 모달에서 하고 되돌리기는 목록에서 받으므로 이 통로를 거친다.
    public private(set) var lastDeleted: DeletedExpense?

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

    /// 수정 화면이 기록을 지웠음을 알린다. 지워진 자리는 되돌릴 때 쓴다.
    public func expenseDidDelete(_ expense: Expense, at index: Int) {
        lastDeleted = DeletedExpense(expense: expense, index: index)
        dataDidChange()
    }

    /// 목록 화면이 스낵바로 넘겨받은 뒤 통로를 비운다.
    public func clearLastDeleted() {
        lastDeleted = nil
    }
}
