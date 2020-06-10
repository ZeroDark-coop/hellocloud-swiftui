//
//  SetupView.swift
//  sample1
//
//  Created by Vincent Moscaritolo on 6/2/20.
//  Copyright © 2020 Zerodark.coop. All rights reserved.
//


import SwiftUI
import ZeroDarkCloud


struct SetupView: UIViewControllerRepresentable {

	@State var candismiss:Bool = true
	
 	fileprivate let initialVC = UIHostingController(rootView: CustomSetupView())
 
	func makeUIViewController(context: Context) -> UIViewController {
		
		let uiTools = ZDCManager.zdc().uiTools!
		
		let setupVC = uiTools.accountSetupViewController(withInitialViewController: initialVC,
																		 canDismissWithoutNewAccount: self.candismiss)
		{ (localUserID: String?, completedActivation: Bool, shouldBackupAccessKey: Bool) in
			
			AppDelegate.sharedInstance().currentLocalUserID = localUserID;
		}
		
		
		initialVC.rootView.proxy = setupVC
		
		return setupVC
	}
    
  
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
	
	init(canDismissWithoutNewAccount:Bool) {
		self.candismiss = canDismissWithoutNewAccount
	}
	
}
 


private let appDisplayName: String? = {
	
	if let bundleDisplayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
		return bundleDisplayName
	} else if let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
		return bundleName
	}
	return nil
}()

fileprivate struct CustomSetupView: View {
	
	public var proxy : ZDCAccountSetupViewControllerProxy?

	let appName = appDisplayName
	
	var body: some View {
 		ZStack {
 			VStack {
	 			Spacer()
				
				Text("\(appName!)")
					.font(.title)
					.foregroundColor(Color.black)
				Image("clouds")
					.accentColor(.black)
	 				.colorMultiply(.black)
				
				Spacer()
				
				Button(action: {
					if let proxy = self.proxy {
						proxy.pushSignInToAccount()
					}
				}) {
					Text("Sign In")
						.padding(.vertical, 20)
						.font(.largeTitle)
				}
 
				Button(action: {
					if let proxy = self.proxy {
						proxy.pushCreateAccount()
					}
					
				}) {
					Text("Create Account")
					.font(.largeTitle)

				}
	 				.padding(.vertical, 20)
				
				Spacer()
			}
			
		}
	}
}
