
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

import Foundation

import libmodbus



public
final
class
MODBUSContext
{
	public
	enum
	Parity
	{
		case none
		case even
		case odd
	}
	
	public
	enum
	RTSMode : Int
	{
		case rs232			=	0
		case rs485			=	1
	}
	
	public	var			customRTS				:	((MODBUSContext, Bool) -> Void)?
	
	public	var			sendDelay				:	Double								=	0.005
	
	/**
		Creates a MODBUS context representing a single bus connected to a system serial port.
		
		- Parameters:
			
			- port:		The POSIX filesystem path to the MODBUS RTU (serial) port.
			- queue:	The queue on which completion closures are called. Defaults to the main queue.
	*/
	
	public
	init(port inPort: String,
			baud inBaud: Int = 115200,
			parity inParity: Parity = .none,
			wordSize inWordSize: Int = 8,
			stopBits inStopBits: Int = 1,
			queue inQueue: DispatchQueue = .main,
			useCustomRTS inUseCustomRTS: Bool = false)
		throws
	{
		guard
			let ctx = modbus_new_rtu(inPort, Int32(inBaud), inParity.charValue, Int32(inWordSize), Int32(inStopBits))
		else
		{
			throw MBError(errno: errno, devID: 0)
		}
		
		self.ctx = ctx
		self.workQ = DispatchQueue(label: "Modbus \(inPort)", qos: .userInitiated)
		self.callbackQ = inQueue
		
		modbus_set_client_context(self.ctx, Unmanaged.passRetained(self).toOpaque())
		
		if inUseCustomRTS
		{
			modbus_rtu_set_rts(self.ctx, Int32(RTSMode.rs485.rawValue))
			modbus_rtu_set_custom_rts(self.ctx)
			{ inCtxPtr, inOn in
				let this: MODBUSContext? = Unmanaged.fromOpaque(modbus_get_client_context(inCtxPtr)).takeUnretainedValue()
				
				if let t = this
				{
					t.customRTS?(t, inOn != 0)
				}
			}
		}
	}
	
	deinit
	{
		modbus_free(self.ctx)
	}
	
	public
	func
	set(debug inDebug: Bool)
	{
		//	The only error returned by ``modbus_set_debug`` is EINVAL, if
		//	the context is not set. We know the context is always valid.
		
		modbus_set_debug(self.ctx, inDebug ? 1 : 0)
	}
	
	public
	func
	connect()
		throws
	{
		let rc = modbus_connect(self.ctx)
		guard
			rc == 0
		else
		{
			throw MBError(errno: errno, devID: self.deviceID)
		}
	}
	
	public
	func
	setByteTimeout(seconds inSeconds: TimeInterval)
		throws
	{
		let v = modf(inSeconds)
		let seconds = UInt32(v.0)
		let usec = UInt32(v.1 * 1000000)
		let rc = modbus_set_byte_timeout(self.ctx, seconds, usec)
		if rc != 0
		{
			throw MBError(errno: errno, devID: self.deviceID)
		}
	}
	
	public
	func
	setResponseTimeout(seconds inSeconds: TimeInterval)
		throws
	{
		let v = modf(inSeconds)
		let seconds = UInt32(v.0)
		let usec = UInt32(v.1 * 1000000)
		let rc = modbus_set_response_timeout(self.ctx, seconds, usec)
		if rc != 0
		{
			throw MBError(errno: errno, devID: self.deviceID)
		}
	}
	
	/**
		The delay between setting/clearing RTS and transmitting bytes. µs
	*/
	
	public
	var
	rtsDelay: Int
	{
		get
		{
			return Int(modbus_rtu_get_rts_delay(self.ctx))
		}
		
		set(inVal)
		{
			modbus_rtu_set_rts_delay(self.ctx, Int32(inVal))
		}
	}
	
	//	MARK: - • Async Methods -
	
	/**
		Asynchronously read the `UInt16` at ``inAddr`` from ``inDeviceID``
	*/
	
	public
	func
	readRegister(fromDevice inDeviceID: Int, atAddress inAddr: Int)
		async
		throws
		-> UInt16
	{
		try await withCheckedThrowingContinuation
		{ inCont in
			self.workQ.asyncAfter(deadline: .now() + self.sendDelay)
			{
				do
				{
					self.deviceID = inDeviceID
					let r: UInt16 = try self.readRegister(address: inAddr)
					inCont.resume(returning: r)
				}
				
				catch (let e)
				{
					inCont.resume(throwing: e)
				}
			}
		}
	}
	
	public
	func
	readRegisters(fromDevice inDeviceID: Int, address inAddr: Int, count inCount: Int)
		async
		throws
		-> [UInt16]
	{
		try await withCheckedThrowingContinuation
		{ inCont in
			self.workQ.asyncAfter(deadline: .now() + self.sendDelay)
			{
				do
				{
					self.deviceID = inDeviceID
					let r: [UInt16] = try self.readRegisters(address: inAddr, count: inCount)
					inCont.resume(returning: r)
				}
				
				catch (let e)
				{
					inCont.resume(throwing: e)
				}
			}
		}
	}
	
	public
	func
	readRegister(fromDevice inDeviceID: Int, atAddress inAddr: Int)
		async
		throws
		-> UInt32
	{
		try await withCheckedThrowingContinuation
		{ inCont in
			self.workQ.asyncAfter(deadline: .now() + self.sendDelay)
			{
				do
				{
					self.deviceID = inDeviceID
					let r: UInt32 = try self.readRegister(address: inAddr)
					inCont.resume(returning: r)
				}
				
				catch (let e)
				{
					inCont.resume(throwing: e)
				}
			}
		}
	}
	
	public
	func
	readRegister(fromDevice inDeviceID: Int, atAddress inAddr: Int)
		async
		throws
		-> Int32
	{
		try await withCheckedThrowingContinuation
		{ inCont in
			self.workQ.asyncAfter(deadline: .now() + self.sendDelay)
			{
				do
				{
					self.deviceID = inDeviceID
					let r: Int32 = try self.readRegister(address: inAddr)
					inCont.resume(returning: r)
				}
				
				catch (let e)
				{
					inCont.resume(throwing: e)
				}
			}
		}
	}
	
	/**
		Asynchronously read the `Float` at ``inAddr`` from ``inDeviceID``
	*/
	
	public
	func
	readRegister(fromDevice inDeviceID: Int, atAddress inAddr: Int)
		async
		throws
		-> Float
	{
		try await withCheckedThrowingContinuation
		{ inCont in
			self.workQ.asyncAfter(deadline: .now() + self.sendDelay)
			{
				do
				{
					self.deviceID = inDeviceID
					let r: Float = try self.read(address: inAddr)
					inCont.resume(returning: r)
				}
				
				catch (let e)
				{
					inCont.resume(throwing: e)
				}
			}
		}
	}
	
	/**
		Asynchronously write the `Float` to ``inDeviceID`` at ``inAddr``
	*/
	
	public
	func
	write(toDevice inDeviceID: Int, atAddress inAddr: Int, value inVal: Float)
		async
		throws
	{
		try await withCheckedThrowingContinuation
		{ (inCont: CheckedContinuation<Void, Error>) -> Void in
			self.workQ.asyncAfter(deadline: .now() + self.sendDelay)
			{
				do
				{
					self.deviceID = inDeviceID
					try self.write(address: inAddr, value: inVal)
					inCont.resume()
				}
				
				catch (let e)
				{
					inCont.resume(throwing: e)
				}
			}
		}
	}
	
	/**
		Asynchronously write the `UInt16` to ``inDeviceID`` at ``inAddr``
	*/
	
	public
	func
	write(toDevice inDeviceID: Int, atAddress inAddr: Int, value inVal: UInt16)
		async
		throws
	{
		try await withCheckedThrowingContinuation
		{ (inCont: CheckedContinuation<Void, Error>) -> Void in
			self.workQ.asyncAfter(deadline: .now() + self.sendDelay)
			{
				do
				{
					self.deviceID = inDeviceID
					try self.write(address: inAddr, values: [inVal])
					inCont.resume()
				}
				
				catch (let e)
				{
					inCont.resume(throwing: e)
				}
			}
		}
	}
	
	public
	func
	write(toDevice inDeviceID: Int, atAddress inAddr: Int, value inVal: Int32)
		async
		throws
	{
		try await withCheckedThrowingContinuation
		{ (inCont: CheckedContinuation<Void, Error>) -> Void in
			self.workQ.asyncAfter(deadline: .now() + self.sendDelay)
			{
				do
				{
					self.deviceID = inDeviceID
					try self.write(address: inAddr, value: inVal)
					inCont.resume()
				}
				
				catch (let e)
				{
					inCont.resume(throwing: e)
				}
			}
		}
	}
	
	/**
		Asynchronously write the array at ``inAddr`` to ``inDeviceID``
	*/
	
	public
	func
	write(toDevice inDeviceID: Int, atAddress inAddr: Int, values inVals: [UInt16])
		async
		throws
	{
		try await withCheckedThrowingContinuation
		{ (inCont: CheckedContinuation<Void, Error>) -> Void in
			self.workQ.asyncAfter(deadline: .now() + self.sendDelay)
			{
				do
				{
					self.deviceID = inDeviceID
					try self.write(address: inAddr, values: inVals)
					inCont.resume()
				}
				
				catch (let e)
				{
					inCont.resume(throwing: e)
				}
			}
		}
	}
	
	@available(*, renamed: "readRegister(address:fromDevice:)")
	public
	func
	readRegister(address inAddr: Int, fromDevice inDeviceID: Int, completion inCompletion: @escaping (UInt16?, Error?) -> ())
	{
		self.workQ.async
		{
			do
			{
				self.deviceID = inDeviceID
				let r: UInt16 = try self.readRegister(address: inAddr)
				self.callbackQ.async { inCompletion(r, nil) }
			}
			
			catch (let e)
			{
				self.callbackQ.async { inCompletion(nil, e) }
			}
		}
	}
	
	/**
		Asynchronously read ``inCount`` `UInt16s` at ``inAddr`` from ``inDeviceID``.
	*/
	
	public
	func
	readRegisters(address inAddr: Int, count inCount: Int, fromDevice inDeviceID: Int, completion inCompletion: @escaping ([UInt16]?, Error?) -> ())
	{
		self.workQ.async
		{
			do
			{
				self.deviceID = inDeviceID
				let r = try self.readRegisters(address: inAddr, count: inCount)
				self.callbackQ.async { inCompletion(r, nil) }
			}
			
			catch (let e)
			{
				self.callbackQ.async { inCompletion(nil, e) }
			}
		}
	}
	
	func
	read(address inAddr: Int, fromDevice inDeviceID: Int, completion inCompletion: @escaping (Float?, Error?) -> ())
	{
		self.workQ.async
		{
			do
			{
				self.deviceID = inDeviceID
				let r: Float = try self.read(address: inAddr)
				self.callbackQ.async { inCompletion(r, nil) }
			}
			
			catch (let e)
			{
				self.callbackQ.async { inCompletion(nil, e) }
			}
		}
	}
	
	func
	readRegister(address inAddr: Int)
		throws
		-> UInt16
	{
//		print("readRegister(address: \(self.deviceID)/\(inAddr)) -> UInt16")
		
		if self.deviceID == -1
		{
			throw MBError.deviceIDNotSet
		}
		
		var v: UInt16 = 0
		let rc = modbus_read_registers(self.ctx, Int32(inAddr), 1, &v)
		if rc == -1
		{
			throw MBError(errno: errno, devID: self.deviceID, addr: inAddr)
		}
		else if rc != 1
		{
			throw MBError.unexpectedReturnedRegisterCount(Int(rc))
		}
		return v
	}
	
	func
	readRegister(address inAddr: Int)
		throws
		-> UInt32
	{
//		print("readRegister(address: \(self.deviceID)/\(inAddr)) -> UInt32")
		
		if self.deviceID == -1
		{
			throw MBError.deviceIDNotSet
		}
		
		let vals = try readRegisters(address: inAddr, count: 2)
		let high = vals[0]
		let low = vals[1]
		let word = UInt32(high) << 16 | UInt32(low)
		return word
	}
	
	func
	readRegister(address inAddr: Int)
		throws
		-> Int32
	{
//		print("readRegister(address: \(self.deviceID)/\(inAddr)) -> Int32")
		
		if self.deviceID == -1
		{
			throw MBError.deviceIDNotSet
		}
		
		let vals = try readRegisters(address: inAddr, count: 2)
		let high = vals[0]
		let low = vals[1]
		let word = Int32(high) << 16 | Int32(low)
		return word
	}
	
	func
	readRegisters(address inAddr: Int, count inCount: Int)
		throws
		-> [UInt16]
	{
//		print("readRegisters(address: \(self.deviceID)/\(inAddr), count: \(inCount)) -> [UInt16]")
		
		if self.deviceID == -1
		{
			throw MBError.deviceIDNotSet
		}
		
		var v = [UInt16](repeating: 0, count: inCount)
		let rc = modbus_read_registers(self.ctx, Int32(inAddr), Int32(inCount), &v)
		if rc == -1
		{
			throw MBError(errno: errno, devID: self.deviceID, addr: inAddr)
		}
		else if rc != inCount
		{
			throw MBError.unexpectedReturnedRegisterCount(Int(rc))
		}
		return v
	}
	
	func
	read(address inAddr: Int)
		throws
		-> Float
	{
//		print("read(address: \(self.deviceID)/\(inAddr)) -> Float")
		
		if self.deviceID == -1
		{
			throw MBError.deviceIDNotSet
		}
		
		let vals = try readRegisters(address: inAddr, count: 2)
		let high = vals[0]
		let low = vals[1]
//		print("high: \(String(format: "0x%04x", high)), low: \(String(format: "0x%04x", low))")
		let word = UInt32(high) << 16 | UInt32(low)
		let r = Float(bitPattern: word)
		return r
	}
	
	func
	write(address inAddr: Int, values inVals: [UInt16])
		throws
	{
		var vals = inVals
		let rc = modbus_write_registers(self.ctx, Int32(inAddr), Int32(inVals.count), &vals)
		if rc != vals.count
		{
			throw MBError(errno: errno, devID: self.deviceID, addr: inAddr, value: String(describing: inVals))
		}
	}
	
	func
	write(address inAddr: Int, value inVal: Float)
		throws
	{
		let bits = inVal.bitPattern
		let word: [UInt16] = [ UInt16(bits >> 16 & 0xFFFF), UInt16(bits & 0xFFFF) ]
		try write(address: inAddr, values: word)
	}
	
	func
	write(address inAddr: Int, value inVal: Int32)
		throws
	{
		let word: [UInt16] = [ UInt16(inVal >> 16 & 0xFFFF), UInt16(inVal & 0xFFFF) ]
		try write(address: inAddr, values: word)
	}
	
	var
	deviceID: Int
	{
		set (inNewValue)
		{
			modbus_set_slave(self.ctx, Int32(inNewValue))
		}
		
		get
		{
			Int(modbus_get_slave(self.ctx))
		}
	}
	
	public
	enum
	SerialMode
	{
		case unknown
		case eia485
		case eia232
	}
	
	public
	var
	serialMode: SerialMode
	{
		set (inNewValue)
		{
			modbus_rtu_set_serial_mode(self.ctx, inNewValue.intValue)
		}
		
		get
		{
			let mode = modbus_rtu_get_serial_mode(self.ctx)
			switch mode
			{
				case 0:		return .eia232
				case 1:		return .eia485
				default:	return .unknown
			}
		}
	}
	
	let			ctx					:	OpaquePointer
	let			workQ				:	DispatchQueue
	let			callbackQ			:	DispatchQueue
}


extension
MODBUSContext.Parity
{
	var
	charValue: CChar
	{
		switch self
		{
			case .none:		return CChar(UInt8(ascii: "N"))
			case .even:		return CChar(UInt8(ascii: "E"))
			case .odd:		return CChar(UInt8(ascii: "O"))
		}
	}
}

extension
MODBUSContext.SerialMode
{
	var
	intValue: Int32
	{
		switch self
		{
			case .eia485:		return 1
			case .eia232:		return 0
			case .unknown:		return 0
		}
	}
}
