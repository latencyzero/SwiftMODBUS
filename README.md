# SwiftMODBUS

A simple Swift wrapper around [libmodbus](https://github.com/stephane/libmodbus). Early days.

## Installation

Add the following to your `Package.swift` `dependencies` section:

```swift
	.package(url: "https://github.com/latencyzero/SwiftMODBUS",					branch: "main"),
```

You will also need to run the following [Brew](https://brew.sh) command:

```bash
$ brew install libmodbus
```

## Build Troubleshooting

If, after updating libmodbus to a new version, you encounter errors like this when building from Xcode:

```
…/SwiftMODBUS/Sources/libmodbus/libmodbus.h:1:10: 'modbus.h' file not found
…/SwiftMODBUS/Sources/SwiftMODBUS/MODBUSContext.swift:1:8: could not build Objective-C module 'libmodbus'
```

try cleaning the project build folder and building again. It seems Xcode
caches the previously-discovered `cflags` from `pkg-config`, and if you update libmodbus, Xcode can't find the new one.

## Roadmap

* Implement remaining functions.
* Improve testing with local server.
* Reimplement purely in Swift to remove `libmodbus` dependency.
