import XCTest
@testable import SwiftMODBUS


//fileprivate let	kPort				=	"/dev/tty.usbserial-AO004DTP"
fileprivate let	kPort				=	"/dev/tty.usbserial-AK05M8LO-"



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
			ctx.set(debug: true)
			ctx.deviceID = 12
			try ctx.connect()
			
			let v: UInt16 = try ctx.readRegister(address: 1000)
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
		ctx.set(debug: true)
		ctx.deviceID = 11
		try ctx.connect()
		
		var v: UInt16 = try ctx.readRegister(address: 1)
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
	testEurothermFloat()
		async
		throws
	{
		let ctx = try MODBUSContext(port: kPort, baud: 19200)
		ctx.set(debug: true)
		try ctx.connect()
		
		var v: Float = try await ctx.readRegister(fromDevice: 11, atAddress: 0x531c)
		print("Sample Temp: \(v)")
		
		v = try await ctx.readRegister(fromDevice: 11, atAddress: 0x50f7)
		print("Furnace Temp: \(v)")
		
		let sbrk: UInt16 = try await ctx.readRegister(fromDevice: 11, atAddress: 0x511f)
		print("Furnace sensor break: \(sbrk)")
		
		let sbrkSample: UInt16 = try await ctx.readRegister(fromDevice: 11, atAddress: 0x5339)
		print("Sample sensor break: \(sbrkSample)")
		
	}
	
	func
	testSetEurothermFloatSP()
		async
		throws
	{
		do
		{
			let ctx = try MODBUSContext(port: kPort, baud: 19200)
			ctx.set(debug: true)
			try ctx.connect()
			
			try await ctx.write(toDevice: 11, atAddress: 0x58ca, value: 123.0)
		}
		
		catch let e
		{
			throw e
		}
	}
	
	func
	testAsync()
		async
		throws
	{
		do
		{
			let ctx = try MODBUSContext(port: kPort, baud: 19200)
			try ctx.setByteTimeout(seconds: 0.1)
			try ctx.setResponseTimeout(seconds: 2)
			try ctx.connect()
			
			let eurothermAddr = 11
			let pvAddr = 0x0001
			let userVal1Addr = 0x1362
			let userVal2Addr = 0x1363
			
			print("Switching to 1")
			try await ctx.write(toDevice: eurothermAddr, atAddress: userVal1Addr, value: UInt16(1))	//	Set to manual control
			try await ctx.write(toDevice: eurothermAddr, atAddress: userVal2Addr, value: UInt16(1))	//	Set to sample TC
			
			var result: UInt16
			var signed: Int16
			
			for i in 0..<10
			{
				result = try await ctx.readRegister(fromDevice: eurothermAddr, atAddress: pvAddr)
		//		print("Eurotherm PV: \(result)")
				signed = Int16(bitPattern: result)
				print("Eurotherm PV 1 \(i): \(signed)")
				
				try await Task.sleep(seconds: 0.001)
			}
			
			//	Set to other TC, read with delay…
			
			print("Switching to 2")
			
			try await ctx.write(toDevice: eurothermAddr, atAddress: userVal2Addr, value: UInt16(2))	//	Set to oven TC
				
			for i in 0..<10
			{
				result = try await ctx.readRegister(fromDevice: eurothermAddr, atAddress: pvAddr)
		//		print("Eurotherm PV: \(result)")
				signed = Int16(bitPattern: result)
				print("Eurotherm PV 2 \(i): \(signed)")
				
				try await Task.sleep(seconds: 0.001)
			}
			
	//		try await ctx.write(toDevice: eurothermAddr, atAddress: userVal2Addr, value: UInt16(1))	//	Set to sample TC
			
			
			
			let alicatAddr = 12
			
			result = try await ctx.readRegister(fromDevice: alicatAddr, atAddress: 1)
			print("Alicat: \(result)")
		}
		
		catch let e
		{
			if let ee = e as? MBError
			{
				print("Error: \(ee)")
			}
		}
	}
	
	func
	testSwitchInput()
		async
		throws
	{
		let ctx = try MODBUSContext(port: kPort, baud: 19200)
		try ctx.connect()
		
		let eurothermAddr = 11
		let userVal1Addr = 0x1362
		let userVal2Addr = 0x1363
		
		var result: UInt16 = try await ctx.readRegister(fromDevice: eurothermAddr, atAddress: userVal1Addr)
		print("Eurotherm UsrVal.1.Val: \(result)")
		
		try await ctx.write(toDevice: eurothermAddr, atAddress: userVal1Addr, value: UInt16(1))	//	Set to manual control
		try await ctx.write(toDevice: eurothermAddr, atAddress: userVal2Addr, value: UInt16(1))
		
		result = try await ctx.readRegister(fromDevice: eurothermAddr, atAddress: userVal1Addr)
		print("Eurotherm UsrVal.1.Val: \(result)")
		
		result = try await ctx.readRegister(fromDevice: eurothermAddr, atAddress: userVal2Addr)
		print("Eurotherm UsrVal.2.Val: \(result)")
	}
	
	func
	testSwitchInputToFurnace()
		async
		throws
	{
		let ctx = try MODBUSContext(port: kPort, baud: 19200)
		try ctx.connect()
		
		let eurothermAddr = 11
		let userVal1Addr = 0x1362
		
		var result: UInt16 = try await ctx.readRegister(fromDevice: eurothermAddr, atAddress: userVal1Addr)
		print("Eurotherm UsrVal.1.Val: \(result)")
		
		try await ctx.write(toDevice: eurothermAddr, atAddress: userVal1Addr, value: UInt16(2))	//	Set to furnace TC
		
		result = try await ctx.readRegister(fromDevice: eurothermAddr, atAddress: userVal1Addr)
		print("Eurotherm UsrVal.1.Val: \(result)")
		
		result = try await ctx.readRegister(fromDevice: eurothermAddr, atAddress: userVal1Addr)
		print("Eurotherm UsrVal.1.Val: \(result)")
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
		
		ctx.readRegister(address: 1, fromDevice: 11)
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
		
		ctx.readRegister(address: 4, fromDevice: 11)
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
		
		ctx.read(address: 4, fromDevice: 11)			//	TODO: This MODBUS register is not float
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


extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
