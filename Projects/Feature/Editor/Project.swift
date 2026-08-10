import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    name: "Editor",
    dependencies: [.domain, .shared, .designSystem]
)
