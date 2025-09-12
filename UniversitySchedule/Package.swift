dependencies: [
    .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["SwiftSoup"]
    )
]
