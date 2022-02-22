# SwiftMODBUS

A simple Swift wrapper around [libmodbus](https://github.com/stephane/libmodbus). Early days.

## Installation


## Build Troubleshooting

If you encounter errors like

```
…/SwiftMODBUS/Sources/libmodbus/libmodbus.h:1:10: 'modbus.h' file not found
…/SwiftMODBUS/Sources/SwiftMODBUS/MODBUSContext.swift:1:8: could not build Objective-C module 'libmodbus'
```

Try cleaning the project build folder and building again. It seems Xcode caches the previously-discovered `cflags`
from `pkg-config`, and if you update libmodbus, Xcode can't find the new one.
