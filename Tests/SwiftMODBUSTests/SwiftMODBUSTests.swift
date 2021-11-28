import XCTest
@testable import SwiftMODBUS


//fileprivate let	kPort				=	"/dev/tty.usbserial-AO004DTP"
fileprivate let	kPort				=	"/dev/tty.usbserial-AK05M8LO"



final
class
SwiftMODBUSTests: XCTestCase
{
	func
	testAlicatAsync()
		async
		throws
	{
		let ctx = try MODBUSContext(port: kPort, baud: 19200)
		try ctx.connect()
		print("write setpoint")
		let f: Float = 1.2345
		try await ctx.write(toDevice: 12, atAddress: 1009, value: f)
	}
	
	func
	testAlicat()
		throws
	{
		do
		{
			let ctx = try MODBUSContext(port: kPort, baud: 19200)
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
		let ctx = try MODBUSContext(port: kPort, baud: 19200)
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
	
	func
	testAsync()
		async
		throws
	{
		let ctx = try MODBUSContext(port: kPort, baud: 19200)
		try ctx.connect()
		
		var result = try await ctx.readRegister(fromDevice: 6, atAddress: 1)
		print("Eurotherm PV: \(result)")
		
		result = try await ctx.readRegister(fromDevice: 7, atAddress: 1)
		print("Alicat: \(result)")
	}
	
	func
	testAsyncClosures()
		throws
	{
		let exp = XCTestExpectation()
		exp.expectedFulfillmentCount = 3
		
		let ctx = try MODBUSContext(port: kPort, baud: 19200)
		ctx.deviceID = 6
		try ctx.connect()
		
		ctx.readRegister(address: 1, fromDevice: 6)
		{ inResult, inError in
			XCTAssertNil(inError)
			XCTAssertNotNil(inResult)
			if let e = inError
			{
				print("Error: \(e)")
				return
			}
			
			print("PV: \(inResult!)")
			exp.fulfill()
		}
		
		ctx.readRegister(address: 4, fromDevice: 6)
		{ inResult, inError in
			XCTAssertNil(inError)
			XCTAssertNotNil(inResult)
			if let e = inError
			{
				print("Error: \(e)")
				return
			}
			
			print("Out: \(inResult!)")
			exp.fulfill()
		}
		
		ctx.read(address: 4, fromDevice: 6)			//	TODO: This MODBUS register is not float
		{ (inResult: Float?, inError: Error?) in
			XCTAssertNil(inError)
			XCTAssertNotNil(inResult)
			if let e = inError
			{
				print("Error: \(e)")
				return
			}
			
			print("PV: \(inResult!)")
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 10)
	}
}
