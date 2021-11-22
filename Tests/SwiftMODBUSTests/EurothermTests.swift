import XCTest
@testable import SwiftMODBUS


final
class
EurothermTests: XCTestCase
{
	func
	testWriteProgram()
		throws
	{
		let bus = try MODBUSContext(port: "", baud: 19200)
		let cont = try Eurotherm(modbus: bus, deviceID: 6)
		
//		cont.getVersion
		
	}
}
