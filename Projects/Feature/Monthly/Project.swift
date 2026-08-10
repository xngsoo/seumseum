import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    name: "Monthly",
    dependencies: [.domain, .shared, .designSystem]
)
