import Foundation
import Testing
import Shared
import Domain
@testable import Daily

/// 조회 도중 멈춰 세울 수 있는 저장소. 로딩 중 상태를 관찰하기 위한 장치.
private actor GatedEmptyRepository: ExpenseRepository {
    private var entered: CheckedContinuation<Void, Never>?
    private var release: CheckedContinuation<Void, Never>?
    private var didEnter = false
    private var isReleased = false

    /// 조회가 시작될 때까지 기다린다.
    func waitUntilEntered() async {
        if didEnter { return }
        await withCheckedContinuation { entered = $0 }
    }

    /// 멈춰 있는 조회를 재개시킨다.
    func releaseNow() {
        isReleased = true
        release?.resume()
        release = nil
    }

    func expenses(on day: Date) async throws -> [Expense] {
        didEnter = true
        entered?.resume()
        entered = nil
        if !isReleased {
            await withCheckedContinuation { release = $0 }
        }
        return []
    }

    func expenses(in range: Range<Date>) async throws -> [Expense] { [] }
    func insert(_ expense: Expense, at index: Int) async throws {}
    func update(_ expense: Expense) async throws {}
    func delete(id: UUID) async throws -> Int { 0 }
    func reorder(_ orderedIDs: [UUID], on day: Date) async throws {}
}

@MainActor
@Suite("빈 날짜 전환")
struct EmptyDayFlickerTests {

    @Test("빈 날짜에서 빈 날짜로 옮겨도 빈 상태가 끊기지 않는다")
    func staysEmptyWhileLoading() async {
        let today = CalendarDay.today()
        let tomorrow = CalendarDay.adding(days: 1, to: today)
        let repository = GatedEmptyRepository()
        let viewModel = DailyViewModel(
            expenseRepository: repository,
            categoryRepository: StubCategoryRepository(categories: [])
        )

        // 첫 로드
        let first = Task { await viewModel.load(day: today) }
        await repository.waitUntilEntered()
        await repository.releaseNow()
        await first.value
        #expect(viewModel.isEmpty, "첫 로드 후 빈 상태여야 한다")

        // 다음 날로 이동 — 조회가 진행 중인 순간을 관찰한다
        let second = Task { await viewModel.load(day: tomorrow) }
        await repository.waitUntilEntered()
        #expect(viewModel.isEmpty, "로딩 중에도 빈 상태여야 화면이 깜빡이지 않는다")
        await repository.releaseNow()
        await second.value
        #expect(viewModel.isEmpty)
    }
}
