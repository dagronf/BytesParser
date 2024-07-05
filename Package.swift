// swift-tools-version: 5.6

import PackageDescription

let package = Package(
	name: "BytesParser",
	products: [
		.library(
			name: "BytesParser",
			targets: ["BytesParser"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
	],
	targets: [
		.target(
			name: "BytesParser",
			dependencies: []),
		.testTarget(
			name: "BytesParserTests",
			dependencies: ["BytesParser"],
			resources: [.process("resources")]
		)
	]
)
