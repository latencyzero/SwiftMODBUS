//
//  Eurotherm.swift
//  
//
//  Created by Rick Mann on 2021-10-13.
//

import Foundation


public
class
Eurotherm
{
	public
	init(modbus inBus: MODBUSContext, deviceID inDeviceID: Int)
	{
		self.bus = inBus
		self.deviceID = inDeviceID
	}
	
	public
	func
	getVersion()
	{
	}
	
	let		bus					:	MODBUSContext
	let		deviceID			:	Int
}
