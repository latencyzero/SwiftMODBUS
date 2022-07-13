// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SwiftMODBUS",
	platforms: [ .macOS(.v12), .iOS(.v15) ],
	products: [
		.library(
			name: "SwiftMODBUS",
			targets: ["SwiftMODBUS"]),
	],
	dependencies: [
	],
	targets: [
		.systemLibrary(name: "libmodbus", pkgConfig: "libmodbus", providers: [.brew(["libmodbus"]), .apt(["libmodbus-dev"])]),
		.target(
			name: "SwiftMODBUS",
			dependencies: [
				"libmodbus",
			]),
		.testTarget(
			name: "SwiftMODBUSTests",
			dependencies: ["SwiftMODBUS"]),
	]
)
