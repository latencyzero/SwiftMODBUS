// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SwiftMODBUS",
	platforms: [ .macOS(.v12), .iOS(.v15) ],
	products: [
		// Products define the executables and libraries a package produces, and make them visible to other packages.
		.library(
			name: "SwiftMODBUS",
			targets: ["SwiftMODBUS"]),
	],
	dependencies: [
		// Dependencies declare other packages that this package depends on.
		// .package(url: /* package url */, from: "1.0.0"),
	],
	targets: [
		.systemLibrary(name: "libmodbus", pkgConfig: "libmodbus", providers: [.brew(["libmodbus"]), .apt(["libmodbus-dev"])]),
		.target(
			name: "SwiftMODBUS",
			dependencies: ["libmodbus"]),
		.testTarget(
			name: "SwiftMODBUSTests",
			dependencies: ["SwiftMODBUS"]),
	]
)
