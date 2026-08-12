import ProjectDescription

// 프로젝트 전역 상수
public enum AppEnvironment {
    public static let appName = "Seumseum"
    public static let organizationName = "xngsoo"
    public static let bundlePrefix = "com.xngsoo.seumseum"
    public static let destinations: Destinations = [.iPhone]
    public static let deploymentTargets: DeploymentTargets = .iOS("17.0")
}

// 공통 빌드 세팅
public let baseSettings: SettingsDictionary = [
    "SWIFT_VERSION": "6.0",
    "SWIFT_STRICT_CONCURRENCY": "complete"
]

// 서명 설정을 포함한 프로젝트 공통 Settings
public let projectSettings: Settings = .settings(
    base: baseSettings,
    configurations: [
        .debug(name: .debug, xcconfig: .relativeToRoot("Tuist/Signing.xcconfig")),
        .release(name: .release, xcconfig: .relativeToRoot("Tuist/Signing.xcconfig"))
    ]
)

// 의존성
public extension TargetDependency {
    static let domain = TargetDependency.project(
        target: "Domain",
        path: .relativeToRoot("Projects/Domain")
    )
    static let shared = TargetDependency.project(
        target: "Shared",
        path: .relativeToRoot("Projects/Core/Shared")
    )
    static let designSystem = TargetDependency.project(
        target: "DesignSystem",
        path: .relativeToRoot("Projects/Core/DesignSystem")
    )
    static let persistence = TargetDependency.project(
        target: "Persistence",
        path: .relativeToRoot("Projects/Core/Persistence")
    )
    static let daily = TargetDependency.project(
        target: "Daily",
        path: .relativeToRoot("Projects/Feature/Daily")
    )
    static let monthly = TargetDependency.project(
        target: "Monthly",
        path: .relativeToRoot("Projects/Feature/Monthly")
    )
    static let statistics = TargetDependency.project(
        target: "Statistics",
        path: .relativeToRoot("Projects/Feature/Statistics")
    )
    static let settings = TargetDependency.project(
        target: "Settings",
        path: .relativeToRoot("Projects/Feature/Settings")
    )
    static let editor = TargetDependency.project(
        target: "Editor",
        path: .relativeToRoot("Projects/Feature/Editor")
    )
}

// 모듈 조립
public extension Project {
    static func module(
        name: String,
        product: Product = .staticFramework,
        dependencies: [TargetDependency] = [],
        hasResources: Bool = false,
        hasTests: Bool = true
    ) -> Project {
        // 1. 소스 타겟
        let sourceTarget: Target = .target(
            name: name,
            destinations: AppEnvironment.destinations,
            product: product,
            bundleId: "\(AppEnvironment.bundlePrefix).\(name)",
            deploymentTargets: AppEnvironment.deploymentTargets,
            infoPlist: .default,
            sources: ["Sources/**"],
            resources: hasResources ? ["Resources/**"] : nil,
            dependencies: dependencies
        )
        
        // 2. 테스트 타겟
        let testTarget: Target? = hasTests ? .target(
            name: "\(name)Tests",
            destinations: AppEnvironment.destinations,
            product: .unitTests,
            bundleId: "\(AppEnvironment.bundlePrefix).\(name)Tests",
            deploymentTargets: AppEnvironment.deploymentTargets,
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: name)],
            settings: .settings(base: ["ENABLE_TESTING_SEARCH_PATHS": "YES"])
        ) : nil
        
        // 3. 조립
        return Project(
            name: name,
            organizationName: AppEnvironment.organizationName,
            settings: projectSettings,
            targets: [sourceTarget, testTarget].compactMap{ $0 }
        )
    }
}

// 앱 타겟 조립
public extension Project {
    static func app(dependencies: [TargetDependency]) -> Project {
        let appTarget: Target = .target(
            name: AppEnvironment.appName,
            destinations: AppEnvironment.destinations,
            product: .app,
            bundleId: AppEnvironment.bundlePrefix,
            deploymentTargets: AppEnvironment.deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "씀씀",
                "CFBundleShortVersionString": "1.0.0",
                "CFBundleVersion": "1",
                "UILaunchScreen": [:],
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
                "UIUserInterfaceStyle": "Automatic",
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: dependencies,
            // 앱 아이콘은 Resources/Assets.xcassets 의 AppIcon 에서 가져온다
            settings: .settings(base: ["ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon"]),
            launchArguments: [.launchArgument(name: "-seedSampleData", isEnabled: false)]
        )
        
        return Project(
            name: AppEnvironment.appName,
            organizationName: AppEnvironment.organizationName,
            settings: projectSettings,
            targets: [appTarget]
        )
    }
}
