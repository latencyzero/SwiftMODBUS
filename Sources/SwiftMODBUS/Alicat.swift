//
//  Alicat.swift
//  
//
//  Created by Rick Mann on 2021-10-23.
//

import Foundation



class
Alicat
{
	init(modbus inBus: MODBUSContext, deviceID inDeviceID: Int)
	{
		self.bus = inBus
		self.deviceID = inDeviceID
	}
	
	let		bus					:	MODBUSContext
	let		deviceID			:	Int
}
