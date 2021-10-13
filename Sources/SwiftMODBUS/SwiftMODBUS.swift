import libmodbus

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

import Foundation





public
class
MBContext
{
	public
	enum
	Parity
	{
		case none
		case even
		case odd
	}
	
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
			queue inQueue: DispatchQueue = .main)
		throws
	{
		self.ctx = modbus_new_rtu(inPort, Int32(inBaud), inParity.charValue, Int32(inWordSize), Int32(inStopBits))
		if self.ctx == nil
		{
			throw MBError(errno: errno)
		}
		
		self.workQ = DispatchQueue(label: "Modbus \(inPort)", qos: .userInitiated)
		self.callbackQ = inQueue
	}
	
	deinit
	{
		modbus_free(self.ctx)
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
			throw MBError(errno: errno)
		}
	}
	
	/**
		Asynchronously read the `UInt16` at ``inAddr`` from ``inDeviceID``
	*/
	
	public
	func
	readRegister(address inAddr: Int, fromDevice inDeviceID: Int, completion inCompletion: @escaping (UInt16?, Error?) -> ())
	{
		self.workQ.async
		{
			do
			{
				self.deviceID = inDeviceID
				let r = try self.readRegister(address: inAddr)
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
	readRegister(address inAddr: Int)
		throws
		-> UInt16
	{
		if self.deviceID == -1
		{
			throw MBError.deviceIDNotSet
		}
		
		var v: UInt16 = 0
		let rc = modbus_read_registers(self.ctx, Int32(inAddr), 1, &v)
		if rc != 1
		{
			throw MBError(errno: errno)
		}
		return v
	}
	
	func
	readRegisters(address inAddr: Int, count inCount: Int)
		throws
		-> [UInt16]
	{
		if self.deviceID == -1
		{
			throw MBError.deviceIDNotSet
		}
		
		var v = [UInt16](repeating: 0, count: inCount)
		let rc = modbus_read_registers(self.ctx, Int32(inAddr), Int32(inCount), &v)
		if rc != inCount
		{
			throw MBError(errno: errno)
		}
		return v
	}
	
	func
	read(address inAddr: Int)
		throws
		-> Float
	{
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
			throw MBError(errno: errno)
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
	
	public
	var
	debug: Bool = false
	{
		didSet
		{
			modbus_set_debug(self.ctx, self.debug ? 1 : 0)
		}
	}
	
	let		ctx					:	OpaquePointer!
	let		workQ				:	DispatchQueue
	let		callbackQ			:	DispatchQueue
}


extension
MBContext.Parity
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
MBContext.SerialMode
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

enum
MBError : Error
{
	case unknown(Int)
	case deviceIDNotSet
	
	case invalidFunction
	case invalidAddress
	case invalidValue
	case serverFailure
	case ack
	case serverBusy
	case nack
	case memoryParity
	case notDefined			//	???
	case gatewayPathUnavailable
	case noResponse
	case invalidCRC
	case invalidData
	case invalidExeceptionCode
	case unknownExeceptionCode
	case dataOverflow		//	Too many bytes returned
	case badServer			//	Response not from requested device
	
	init(errno inErr: Int32)
	{
		let kErrorBase = 112345678
		switch inErr
		{
			case Int32(kErrorBase +  1):	self = .invalidFunction
			case Int32(kErrorBase +  2):	self = .invalidAddress
			case Int32(kErrorBase +  3):	self = .invalidValue
			case Int32(kErrorBase +  4):	self = .serverFailure
			case Int32(kErrorBase +  5):	self = .ack
			case Int32(kErrorBase +  6):	self = .serverBusy
			case Int32(kErrorBase +  7):	self = .nack
			case Int32(kErrorBase +  8):	self = .memoryParity
			case Int32(kErrorBase +  9):	self = .notDefined
			case Int32(kErrorBase + 10):	self = .gatewayPathUnavailable
			case Int32(kErrorBase + 11):	self = .noResponse
			case Int32(kErrorBase + 12):	self = .invalidCRC
			case Int32(kErrorBase + 13):	self = .invalidData
			case Int32(kErrorBase + 14):	self = .invalidExeceptionCode
			case Int32(kErrorBase + 15):	self = .unknownExeceptionCode
			case Int32(kErrorBase + 16):	self = .dataOverflow
			case Int32(kErrorBase + 17):	self = .badServer
			default:						self = .unknown(Int(inErr))
		}
	}
}

extension
MBError : CustomDebugStringConvertible
{
	var
	debugDescription: String
	{
		if case let .unknown(error) = self
		{
			return errDesc(error)
		}
		else
		{
			return String(describing: self)
		}
	}
	
}

func
errDesc(_ inErr: Int)
	-> String
{
	let s = String(validatingUTF8: modbus_strerror(Int32(inErr))) ?? "Unable to convert error string"
	return s
}

//const char *modbus_strerror(int errnum) {
//    switch (errnum) {
//    case EMBXILFUN:
//        return "Illegal function";
//    case EMBXILADD:
//        return "Illegal data address";
//    case EMBXILVAL:
//        return "Illegal data value";
//    case EMBXSFAIL:
//        return "Slave device or server failure";
//    case EMBXACK:
//        return "Acknowledge";
//    case EMBXSBUSY:
//        return "Slave device or server is busy";
//    case EMBXNACK:
//        return "Negative acknowledge";
//    case EMBXMEMPAR:
//        return "Memory parity error";
//    case EMBXGPATH:
//        return "Gateway path unavailable";
//    case EMBXGTAR:
//        return "Target device failed to respond";
//    case EMBBADCRC:
//        return "Invalid CRC";
//    case EMBBADDATA:
//        return "Invalid data";
//    case EMBBADEXC:
//        return "Invalid exception code";
//    case EMBMDATA:
//        return "Too many data";
//    case EMBBADSLAVE:
//        return "Response not from requested slave";
//    default:
//        return strerror(errnum);
//    }
//}
