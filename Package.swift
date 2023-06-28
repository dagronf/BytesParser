// swift-tools-version: 5.4

import PackageDescription

let package = Package(
	name: "BytesParser",
	products: [
		.library(
			name: "BytesParser",
			targets: ["BytesParser"]),
	],
	dependencies: [],
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
