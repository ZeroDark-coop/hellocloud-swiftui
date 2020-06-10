//
//  ContentView.swift
//  sample1
//
//  Created by Vincent Moscaritolo on 6/2/20.
//  Copyright © 2020 Zerodark.coop. All rights reserved.
//

import SwiftUI
import ZeroDarkCloud


struct AvatarNavigationButton: View {
	
	private var size: CGFloat;
	private var userID : String?
	private var nav:UINavigationController?
	private var displayName = ""
	
	init(userID :String,
		  size:CGFloat? = nil,
		  navigationController:UINavigationController) {
		
		self.size = size ?? 32
		self.userID = userID
		self.nav = navigationController
		
		let  	databaseConnection :YapDatabaseConnection = ZDCManager.zdc().databaseManager!.uiDatabaseConnection
		
		databaseConnection.read { (transaction) in
			
			guard let user = transaction.localUser(id: userID) else {
				fatalError("user \(String(describing: userID)) not found !")
			}
			
			self.displayName = user.displayName
		}
		
	}
	
	var body: some View {
		return Button(action: {
			ZDCManager.zdc().uiTools?.pushSettings(forLocalUserID: self.userID!,
																with:self.nav!)
			
		}
		) {
			
			HStack() {
				AvatarImage(userID: userID!, size: size)
				Text("\(displayName)")
					.font(.callout)
					.allowsTightening(true)
					.lineLimit(1)
					.minimumScaleFactor(0.5)
				
			}
		}
		
		
	}
	
}


fileprivate struct AppOrContinueView: View {
	
	@Binding var showMenu: Bool
	@Binding var userCompletedSetup: Bool
	
	var body: some View {
		
		return
			ZStack {
				if(userCompletedSetup) {
					AppView(showMenu: self.$showMenu)
				}
				else {
					ContinueSetupView()
				}
		}
	}
}


fileprivate struct EmbededSetup: View {
	
	@Binding var showMenu: Bool
	
	var body: some View {
		
		GeometryReader { geometry in
			ZStack(alignment: .leading) {
				
				SetupView(canDismissWithoutNewAccount: true)
					.frame(width: geometry.size.width, height: geometry.size.height)
					.offset(x: self.showMenu ? geometry.size.width/2 : 0)
					.disabled(self.showMenu ? true : false)
				if self.showMenu {
					MenuView(showMenu: self.$showMenu )
						.frame(width: geometry.size.width/2)
						.transition(.move(edge: .leading))
				}
			}
		}
	}
	
}


fileprivate struct EmbededContent: View {
	
	@Binding var showMenu: Bool
	
	var nav: UINavigationController?
	
	let 	localUserID = AppDelegate.sharedInstance().currentLocalUserID
	
	@State var userCompletedSetup: Bool = false
	@State var displayName: String?
	
	var body: some View {
		
		let drag = DragGesture()
			.onEnded {
				if $0.translation.width < -100 {
					withAnimation {
						self.showMenu = false
					}
				}
		}
		
		return
			GeometryReader { geometry in
				ZStack(alignment: .leading) {
					AppOrContinueView(showMenu: self.$showMenu,
											userCompletedSetup: self.$userCompletedSetup)
						.frame(width: geometry.size.width, height: geometry.size.height)
						.offset(x: self.showMenu ? geometry.size.width/2 : 0)
						//							.disabled(self.showMenu ? true : false)
						.gesture(drag)
					
					if self.showMenu {
						MenuView(showMenu: self.$showMenu)
							.frame(width: geometry.size.width/2)
							.transition(.move(edge: .leading))
					}
				}
			}
			.navigationBarTitle("", displayMode: .inline)
			.navigationBarItems(leading:
				HStack{
					Button(action: {
						withAnimation(.easeInOut(duration: 0.3)) {
							self.showMenu.toggle()
						}
					}) {
						Image(systemName: "line.horizontal.3")
							.imageScale(.large)
					}.padding(16)
					
					if(self.userCompletedSetup)
					{
						Spacer()
						
						// I check displayName to force update each time
						if(self.displayName != nil){
							
							AvatarNavigationButton(userID: self.localUserID!,
														  size:28,
														  navigationController: self.nav!)
							
						}
						
						
						//					.padding(UIScreen.main.bounds.size.width/4)
					}
					
					
				}
			)
				.onAppear {
					
					let  	databaseConnection :YapDatabaseConnection = ZDCManager.zdc().databaseManager!.uiDatabaseConnection
					
					databaseConnection.read { (transaction) in
						
						if let  userID =  AppDelegate.sharedInstance().currentLocalUserID
						{
							if let localUser = transaction.object(forKey: userID, inCollection: kZDCCollection_Users) as? ZDCLocalUser {
								if (localUser.hasCompletedSetup && !localUser.accountNeedsA0Token)  {
									self.userCompletedSetup = true
								}
								
								self.displayName = localUser.displayName
								
							}
						}
					}
		}
	}
}


struct ContentView: View {
	
	@State var showMenu = false
	var nav : UINavigationController?
	
	var body: some View {
		
		EmbededContent(showMenu: self.$showMenu,
							nav: self.nav )
		
	}
}






