import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    name: "Statistics",
    dependencies: [.domain, .shared, .designSystem]
)
