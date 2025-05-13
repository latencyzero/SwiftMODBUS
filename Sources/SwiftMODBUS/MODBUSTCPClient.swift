////
////  ModbusTCPClient.swift
////  SwiftMODBUS
////
////  Created by Rick Mann on 2025-05-08.
////
//
//import Foundation
//import NIOCore
//import NIOPosix
//
//
//#if false
//
//
//
//public
//actor
//ModbusTCPClient
//{
//	private var decoder: ModbusTCPDecoder?
//
//	public
//	init(host inHost: String,
//				port inPort: Int = 502,
//				unitID inUnitID: UInt8 = 1,
//				eventLoopGroup inGroup: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1))
//	{
//		self.host = inHost
//		self.port = inPort
//		self.unitID = inUnitID
//		self.group = inGroup
//		self.transactionID = 0
//	}
//
//	let		host			: String
//	let		port			: Int
//	let		unitID			: UInt8
//	let		group			: EventLoopGroup
//	var		transactionID	: UInt16
//	var		channel			: Channel?
//
//	public
//	func
//	connect()
//		async
//		throws
//	{
//		let bootstrap = ClientBootstrap(group: self.group)
//			.channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
//			.channelInitializer { channel in
//				let decoder = ModbusTCPDecoder()
//				self.decoder = decoder
//				return channel.pipeline.addHandler(ByteToMessageHandler(decoder))
//			}
//
//		self.channel = try await bootstrap.connect(host: self.host, port: self.port).get()
//	}
//
//	public
//	func
//disconnect()
//	{
//		self.decoder?.failAllPending(with: ModbusError.noHandler)
//		try? self.channel?.close().wait()
//		self.channel = nil
//	}
//
//	public
//	func
//	readRegisters(address inAddr: UInt16, count inCount: UInt16)
//		async
//		throws
//		-> [UInt16]
//	{
//		let tid = self.transactionID
//		self.transactionID &+= 1
//
//		let pdu = ModbusRequest.readHoldingRegisters(unitID: self.unitID,
//																transactionID: tid,
//																address: inAddr,
//																count: inCount)
//
//		guard let chan = self.channel else { throw ModbusError.noHandler }
//		try await chan.writeAndFlushAsync(pdu)
//
//		return try await withCheckedThrowingContinuation { cont in
//			self.decoder.setContinuation(for: tid, cont: cont)
//		}
//	}
//
//	public
//	func
//	writeRegisters(address inAddr: UInt16, values inVals: [UInt16])
//		async
//		throws
//	{
//		let tid = self.transactionID
//		self.transactionID &+= 1
//
//		let pdu = ModbusRequest.writeMultipleRegisters(unitID: self.unitID,
//																			transactionID: tid,
//																			address: inAddr,
//																			values: inVals)
//
//		guard let chan = self.channel else { throw ModbusError.noHandler }
//		try await chan.writeAndFlushAsync(pdu)
//
//		_ = try await withCheckedThrowingContinuation { cont in
//			ModbusTCPDecoder.shared.setContinuation(for: tid, cont: cont)
//		}
//	}
//}
//
//public
//extension
//Channel
//{
//	func
//	writeAndFlushAsync(_ data: ByteBuffer)
//		async
//		throws
//	{
//		try await withCheckedThrowingContinuation { cont in
//			self.writeAndFlush(data).whenComplete { result in
//				switch result
//				{
//					case .success: cont.resume()
//					case .failure(let error): cont.resume(throwing: error)
//				}
//			}
//		}
//	}
//}
//
//public
//enum
//ModbusError : Error
//{
//	case badResponse
//	case deviceError(code: UInt8)
//	case unexpectedFunctionCode
//	case noHandler
//}
//
//internal
//struct
//ModbusRequest
//{
//	static
//	func
//	readHoldingRegisters(unitID: UInt8, transactionID: UInt16, address: UInt16, count: UInt16) -> ByteBuffer
//	{
//		var buffer = ByteBufferAllocator().buffer(capacity: 12)
//		buffer.writeInteger(transactionID, endianness: .big)
//		buffer.writeInteger(UInt16(0), endianness: .big)
//		buffer.writeInteger(UInt16(6), endianness: .big)
//		buffer.writeInteger(unitID)
//		buffer.writeInteger(UInt8(0x03))
//		buffer.writeInteger(address, endianness: .big)
//		buffer.writeInteger(count, endianness: .big)
//		return buffer
//	}
//
//	static
//	func
//	writeMultipleRegisters(unitID: UInt8, transactionID: UInt16, address: UInt16, values: [UInt16]) -> ByteBuffer
//	{
//		let byteCount = UInt8(values.count * 2)
//		let length = UInt16(7 + byteCount)
//		var buffer = ByteBufferAllocator().buffer(capacity: Int(length) + 6)
//		buffer.writeInteger(transactionID, endianness: .big)
//		buffer.writeInteger(UInt16(0), endianness: .big)
//		buffer.writeInteger(length, endianness: .big)
//		buffer.writeInteger(unitID)
//		buffer.writeInteger(UInt8(0x10))
//		buffer.writeInteger(address, endianness: .big)
//		buffer.writeInteger(UInt16(values.count), endianness: .big)
//		buffer.writeInteger(byteCount)
//		for v in values {
//			buffer.writeInteger(v, endianness: .big)
//		}
//		return buffer
//	}
//}
//
//internal
//final
//class
//ModbusTCPDecoder : ByteToMessageDecoder
//{
//	typealias InboundOut = [UInt16]
//	// removed shared singleton
//	var pending: [UInt16: CheckedContinuation<[UInt16], Error>] = [:]
//
//	func decode(context: NIOCore.ChannelHandlerContext, buffer: inout NIOCore.ByteBuffer) throws -> NIOCore.DecodingState
//	{
//		guard buffer.readableBytes >= 9 else {
//			return .needMoreData
//		}
//
//		let tid = buffer.readInteger(as: UInt16.self)!
//		_ = buffer.readInteger(as: UInt16.self)!
//		let length = buffer.readInteger(as: UInt16.self)!
//		let unitID = buffer.readInteger(as: UInt8.self)!
//		let function = buffer.readInteger(as: UInt8.self)!
//
//		if function & 0x80 != 0 {
//			guard buffer.readableBytes >= 1 else {
//				return .needMoreData
//			}
//			let code = buffer.readInteger(as: UInt8.self)!
//			pending.removeValue(forKey: tid)?.resume(throwing: ModbusError.deviceError(code: code))
//			return .continue
//		}
//
//		switch function
//		{
//			case 0x03:
//				guard buffer.readableBytes >= 1 else { return .needMoreData }
//				let byteCount = buffer.readInteger(as: UInt8.self)!
//				guard buffer.readableBytes >= byteCount else { return .needMoreData }
//				var registers: [UInt16] = []
//				for _ in 0..<(byteCount / 2) {
//					registers.append(buffer.readInteger(as: UInt16.self)!)
//				}
//				pending.removeValue(forKey: tid)?.resume(returning: registers)
//				return .continue
//			case 0x10:
//				pending.removeValue(forKey: tid)?.resume(returning: [])
//				return .continue
//			default:
//				pending.removeValue(forKey: tid)?.resume(throwing: ModbusError.unexpectedFunctionCode)
//				return .continue
//		}
//	}
//
//	func setContinuation(for tid: UInt16, cont: CheckedContinuation<[UInt16], Error>)
//	{
//		pending[tid] = cont
//	}
//
//	func failAllPending(with error: Error) {
//		for (_, cont) in pending {
//			cont.resume(throwing: error)
//		}
//		pending.removeAll()
//	}
//}
//
//#endif
