import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    name: "Settings",
    dependencies: [.domain, .shared, .designSystem]
)
