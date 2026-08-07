import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    name: "Persistence",
    dependencies: [.domain, .shared]
)
