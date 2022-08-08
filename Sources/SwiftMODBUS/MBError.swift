//
//  MBError.swift
//  
//
//  Created by Rick Mann on 2022-07-25.
//

import Foundation

import libmodbus



public
enum
MBError : Error
{
	case unknown(Int)
	case deviceIDNotSet
	case unexpectedReturnedRegisterCount(Int)
	case timeout(Int, Int)							//	Device ID, MODBUS address
	
	//	libmodbus errors
	
	case invalidFunction
	case invalidAddress(Int?)
	case invalidValue(Int, Int?, String?)
	case serverFailure
	case ack
	case serverBusy
	case nack
	case memoryParity
	case notDefined									//	???
	case gatewayPathUnavailable
	case noResponse
	case invalidCRC
	case invalidData
	case invalidExeceptionCode
	case unknownExeceptionCode
	case dataOverflow								//	Too many bytes returned
	case badServer									//	Response not from requested device
	
	
	/**
		Pass the address or formatted value to improve the error message context.
	*/
	
	init(errno inErr: Int32, devID inDevID: Int, addr inAddr: Int? = nil, value inVal: String? = nil)
	{
		let kErrorBase = 112345678
		switch inErr
		{
			case Int32(kErrorBase +  1):	self = .invalidFunction
			case Int32(kErrorBase +  2):	self = .invalidAddress(inAddr)
			case Int32(kErrorBase +  3):	self = .invalidValue(inDevID, inAddr, inVal)
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
			
			case Int32(ETIMEDOUT):			self = .timeout(inDevID, inAddr ?? 0)
			
			default:						self = .unknown(Int(inErr))
		}
	}
}

extension
MBError : CustomDebugStringConvertible
{
	public
	var
	debugDescription: String
	{
		var s: String
		switch self
		{
			case .unknown(let ec):								s = "Unknown libmodbus error (errno: \(ec))"
			case .deviceIDNotSet:								s = "Device ID not set"
			case .unexpectedReturnedRegisterCount(let c):		s = "Unexpected returned register count: \(c)"
			case .timeout(let dev, let addr):					s = "Timeout (dev/addr: \(dev)/\(addr))"			//	TODO: format?
			
			case .invalidFunction:								s = "Invalid function"
			case .invalidAddress(let a):						s = "Invalid address \(String(describing: a))"
			case .invalidValue(let d, let a, let v):
				if let a = a,
					let v = v
				{
					s = "Invalid value \(d)/\(a): \(v)"
				}
				else if let a = a
				{
					s = "Invalid value \(d)/\(a)"
				}
				else
				{
					s = "Invalid value for device \(d)"
				}
			
			case .serverFailure:								s = "Server failure"
			case .ack:											s = "Acknowledged"
			case .serverBusy:									s = "Server busy"
			case .nack:											s = "Not acknowledged"
			case .memoryParity:									s = "Memory parity"
			case .notDefined:									s = "Error not defined"
			case .gatewayPathUnavailable:						s = "Gateway path unavailable"
			case .noResponse:									s = "No response"
			
			case .invalidCRC:									s = "Invalid CRC"
			case .invalidData:									s = "Invalid data"
			case .invalidExeceptionCode:						s = "Invalid exception code"
			case .unknownExeceptionCode:						s = "Unknown exception code"
			case .dataOverflow:									s = "Data overflow"
			case .badServer:									s = "Response not from requested device"
		}
		
		s = "SwiftMODBUS Error: \(s)"
		return s
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
