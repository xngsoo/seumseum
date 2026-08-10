import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.app(
    dependencies: [.domain, .shared, .designSystem, .persistence, .daily, .editor, .monthly, .statistics]
)
