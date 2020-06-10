//
//  ContinueSetup.swift
//  sample1
//
//  Created by Vincent Moscaritolo on 6/4/20.
//  Copyright © 2020 Zerodark.coop. All rights reserved.
//

import SwiftUI
import ZeroDarkCloud

struct ContinueSetupView: View {
		
	let 	localUserID = AppDelegate.sharedInstance().currentLocalUserID
	@State var displayName:String = ""
	
	
	var body: some View {
		
		ZStack(alignment: .center) {
			GeometryReader { geometry in
				
				VStack {
					AvatarImage(userID: self.localUserID!, size: geometry.size.width/4)
					Text("\(self.displayName)")
						.font(.title)
					
					Button(action: {
						AppDelegate.sharedInstance().showResumeActivationView(localUserID: self.localUserID!)
					}) {
						Text("Continue Setup")
							.padding(.vertical, 20)
							.font(.largeTitle)
					}
					
				}
			}
		}.onAppear() {
			
			
			let  	databaseConnection :YapDatabaseConnection = ZDCManager.zdc().databaseManager!.uiDatabaseConnection
			
			databaseConnection.read { (transaction) in
				
				if let  userID =  AppDelegate.sharedInstance().currentLocalUserID
				{
					if let localUser = transaction.object(forKey: userID, inCollection: kZDCCollection_Users) as? ZDCLocalUser {
						self.displayName = localUser.displayName
					}
					
				}
				
			}
		}
	}
	
}

