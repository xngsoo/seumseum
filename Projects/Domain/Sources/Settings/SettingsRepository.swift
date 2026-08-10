import Foundation

public protocol SettingsRepository: Sendable {
    func settings() async throws -> AppSettings
    func update(_ settings: AppSettings) async throws
}
