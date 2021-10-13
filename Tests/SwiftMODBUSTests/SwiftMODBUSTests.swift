import XCTest
@testable import SwiftMODBUS


final
class
SwiftMODBUSTests: XCTestCase
{
	func
	testAlicat()
		throws
	{
		do
		{
			let ctx = try MBContext(port: "/dev/tty.usbserial-AO004DTP", baud: 19200)
			ctx.debug = true
			ctx.deviceID = 1
			try ctx.connect()
			
			let v = try ctx.readRegister(address: 1000)
			print("Register: \(v)")
			
			var f: Float = try ctx.read(address: 1202)
			print("Pressure: \(f)")
			
			f = try ctx.read(address: 1210)
			print("Setpoint: \(f)")
			
			print("write setpoint")
			f = 0.321
			try ctx.write(address: 1009, value: f)
			
			f = try ctx.read(address: 1210)
			print("Setpoint: \(f)")
			XCTAssertEqual(f, 0.321, accuracy: 0.0002)
			
	//		for _ in 0..<100000
	//		{
	//			f = try ctx.read(address: 1208)
	//			print("Flow: \(f)")
	//		}
		}
		
		catch (let e)
		{
			if case let MBError.unknown(err) = e
			{
				print("Errno: \(err)")
			}
			print("Err: \(e)")
			throw e
		}
	}
	
	func
	testEurotherm()
		throws
	{
		let ctx = try MBContext(port: "/dev/tty.usbserial-A600euQU", baud: 19200)
		ctx.debug = false
		ctx.deviceID = 6
		try ctx.connect()
		
		var v = try ctx.readRegister(address: 1)
		print("PV: \(v)")
		
		v = try ctx.readRegister(address: 2)
		print("TargetSP: \(v)")
		
		try ctx.write(address: 24, values: [20])
		
		v = try ctx.readRegister(address: 2)
		print("TargetSP: \(v)")
		
		v = try ctx.readRegister(address: 107)
		print("Version: \(v)")
		
	}
}
