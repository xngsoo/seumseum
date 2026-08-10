import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    name: "Daily",
    dependencies: [.domain, .shared, .designSystem]
)
