//
//  CustomLogFormatter.swift
//  sample1
//
//  Created by Vincent Moscaritolo on 6/2/20.
//  Copyright © 2020 Zerodark.coop. All rights reserved.
//

import Foundation
/// ZeroDark.cloud
///
/// Homepage      : https://www.zerodark.cloud
/// GitHub        : https://github.com/4th-ATechnologies/ZeroDark.cloud
/// Documentation : https://zerodarkcloud.readthedocs.io/en/latest
/// API Reference : https://apis.zerodark.cloud
///
/// Sample App: helloccloud

import Foundation
import CocoaLumberjack

/// Demonstrating some cool things you can do via CocoaLumberjack.
///
class CustomLogFormatter: NSObject, DDLogFormatter {
	
	let dateFormatter: DateFormatter
	
	override init() {
		dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "HH:mm:ss:SSS"
	}
	
	func format(message logMessage: DDLogMessage) -> String? {
		
		let ts = dateFormatter.string(from: logMessage.timestamp)
		let msg = logMessage.message
		
		if logMessage.context == 1 { // logMessage is coming from ZeroDarkCloud framework
			return "\(ts): 🔨 \(msg)"
		}
		else if logMessage.context == 27017 { // logMessage is coming from YapDatabase framework
			return "\(ts): 🗄 \(msg)"
		}
		else {
			
			let emoji: String;
			switch logMessage.fileName {
				case "ZDCManager" : emoji = "🍒"
				default           : emoji = "📓"
			}
			
			return "\(ts): \(emoji) \(msg)"
		}
	}
}
