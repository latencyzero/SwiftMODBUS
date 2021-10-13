//
//  File.swift
//  
//
//  Created by Rick Mann on 2021-10-13.
//

import Foundation



class
Eurotherm
{
	init(modbus inBus: MBContext, deviceID inDeviceID: Int)
	{
		self.bus = inBus
		self.deviceID = inDeviceID
	}
	
	let		bus					:	MBContext
	let		deviceID			:	Int
}
