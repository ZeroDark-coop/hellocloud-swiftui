//
//  AppDelegate.swift
//  sample1
//
//  Created by Vincent Moscaritolo on 6/2/20.
//  Copyright © 2020 Zerodark.coop. All rights reserved.
//

import UIKit
import SwiftUI
import Photos

import YapDatabase
import ZeroDarkCloud

import CocoaLumberjack

extension UIApplication {
	
	func setRootVC(_ vc : UIViewController){
		self.windows.first?.rootViewController = vc
		self.windows.first?.makeKeyAndVisible()
	}
 }



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	
	fileprivate var _currentLocalUserID : String? = nil
	
	/// Utility method (less typing)
	///
	class func sharedInstance() -> AppDelegate{
		return UIApplication.shared.delegate as! AppDelegate
	}
	
	
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		
		// Configure CocoaLumberjack
		#if DEBUG
		dynamicLogLevel = .all
		#else
		dynamicLogLevel = .warning
		#endif
		
		DDTTYLogger.sharedInstance!.logFormatter = CustomLogFormatter()
		DDLog.add(DDTTYLogger.sharedInstance!)
		
		ZeroDarkCloud.setLogHandler({ (log: ZDCLogMessage) in
			
			// Convert to CocoaLumberjack log
			let message =
				DDLogMessage.init(message: log.message,
										level: DDLogLevel(rawValue: log.level.rawValue)!,
										flag: DDLogFlag(rawValue: log.flag.rawValue),
										context: 1, // <= Used in CustomLogFormatter.swift
					file: log.file,
					function: log.function,
					line: log.line,
					tag: nil,
					options: [],
					timestamp: Date())
			
			// And pump log message into CocoaLumberjack system
			DDLog.log(asynchronous: false, message: message)
		})
		
		// Setup ZeroDarkCloud
		let _ = ZDCManager.sharedInstance;
		
		// Register with APNs
		UIApplication.shared.registerForRemoteNotifications()
		
		return true
	}
	
	func application(_ application: UIApplication,
						  didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
	{
		print("didRegisterForRemoteNotifications")
		
		// Forward the token to ZeroDarkCloud framework,
		// which will automatically register it with the server.
		ZDCManager.zdc().didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
	}
	
	func application(_ application: UIApplication,
						  didFailToRegisterForRemoteNotificationsWithError error: Error)
	{
		// The token is not currently available.
		print("Remote notification support is unavailable due to error: \(error.localizedDescription)")
	}
	
	func application(_ application: UIApplication,
						  didReceiveRemoteNotification userInfo: [AnyHashable : Any],
						  fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
	{
		print("Remote notification: \(userInfo)")
		
		// Forward to ZeroDarkCloud framework
		ZDCManager.zdc().didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
	}
	
	
	// MARK: UISceneSession Lifecycle
	
	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}
	
	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: User Management
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	/// The app allows you to login to multiple users.
	/// However, even if you login as both Alice & Bob, the UI is only showing one user at-a-time.
	/// That is, it's either showing Alice's stuff or Bob's stuff.
	/// So the UI has a notion of the "current" localUser that's being shown.
	/// This method provides a convenient way to get that localUserID.
	///
	
	
	var currentLocalUserID: String?
	{
		get {
			if (_currentLocalUserID == nil)
			{
				var allUsersIDs:Array<String> = []
				
				let zdc = ZDCManager.zdc()
				let uiDatabaseConnection = zdc.databaseManager!.uiDatabaseConnection
				uiDatabaseConnection.read { (transaction) in
					
					allUsersIDs = zdc.localUserManager!.allLocalUserIDs(transaction)
				}
				
				_currentLocalUserID = allUsersIDs.first
			}
			
			return _currentLocalUserID
		}
		set(localUserID) {
			
			if localUserID != _currentLocalUserID {
				
				_currentLocalUserID = localUserID
				if _currentLocalUserID == nil {
					// fallback to current User
					_currentLocalUserID = self.currentLocalUserID
				}
			}
			
			// does tha user still exist
			var localUser: ZDCLocalUser?
			if let luid = _currentLocalUserID {
				
				let zdc = ZDCManager.zdc()
				let uiDatabaseConnection = zdc.databaseManager!.uiDatabaseConnection
				uiDatabaseConnection.read { (transaction) in
					
					localUser = transaction.object(forKey: luid, inCollection: kZDCCollection_Users) as? ZDCLocalUser
				}
			}
			
			if (localUser != nil) {
				self.showMainView()
 			}
			else {
				self.showActivationView(canDismissWithoutNewAccount: false)
 			}
		}
	}
	
	func deleteUserID(userID:String!, completion: @escaping (Bool) -> ()) {
		
		let zdc = ZDCManager.zdc()
		let rwDatabaseConnection = zdc.databaseManager!.rwDatabaseConnection
		
		rwDatabaseConnection.asyncReadWrite({ (transaction) in
			
			//			let listsIDs = ListsViewController.allListsWithLocalUserID(userID: userID, transaction: transaction)
			
			zdc.localUserManager?.deleteLocalUser(userID, transaction: transaction)
			
			//			for listID in listsIDs {
			//
			//				transaction.removeObject(forKey: listID,
			//										 inCollection: kCollection_Lists)
			//
			//			}
			
		}, completionBlock: {
			
			completion(true)
		})
	}
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: VIEW Management
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	func showActivationView(canDismissWithoutNewAccount: Bool) {
		
		// Create the SwiftUI view that provides the window contents.
		let initialVC = UIHostingController(rootView: SetupView(canDismissWithoutNewAccount: canDismissWithoutNewAccount))
		UIApplication.shared.setRootVC(initialVC)
}
	
	func showResumeActivationView(localUserID: String)
	{
		let uiTools = ZDCManager.zdc().uiTools!
		
		let setupVC = uiTools.accountResumeSetup(forLocalUserID: localUserID)
		{ (localUserID: String?, completedActivation: Bool, shouldBackupAccessKey: Bool) in
			
			AppDelegate.sharedInstance().currentLocalUserID = localUserID;
		}
		
		//		initialVC.rootView.proxy = setupVC
		UIApplication.shared.setRootVC(setupVC)
	}
 
	
	
	func showMainView(){
		
		let vc = UIHostingController(rootView: ContentView())
		
		let topVC =  UIApplication.shared.windows.first?.rootViewController
		if(topVC is UINavigationController)
		{
			let nav = topVC as! UINavigationController
			vc.rootView.nav = nav
			nav.setViewControllers([vc], animated: true	)
		}
		else
		{
			let nav =  UINavigationController(rootViewController: vc)
			vc.rootView.nav = nav
			UIApplication.shared.setRootVC(nav)
		}
	}
	
	func pushSettinsView(){
		
		let topVC =  UIApplication.shared.windows.first?.rootViewController
		let nav = topVC as! UINavigationController
		let settingVC = UIHostingController(rootView: SettingsView())
		nav.pushViewController(settingVC, animated: true)
	}
	
	
	func pushBackupView(userID:String!)
	{
		// does tha user still exist
		var localUser: ZDCLocalUser?
		if let luid = userID {
			
			let zdc = ZDCManager.zdc()
			let uiDatabaseConnection = zdc.databaseManager!.uiDatabaseConnection
			uiDatabaseConnection.read { (transaction) in
				
				localUser = transaction.object(forKey: luid, inCollection: kZDCCollection_Users) as? ZDCLocalUser
			}
		}
		
		if let localUser = localUser {
			
			//only backup users that complete setup
			if(localUser.hasCompletedSetup ){
				
				_currentLocalUserID = localUser.uuid;
				
				let vc = UIHostingController(rootView: ContentView())
				let navController =  UINavigationController(rootViewController: vc)
				vc.rootView.nav = navController
				UIApplication.shared.setRootVC(navController)
				
				ZDCManager.zdc().uiTools!.pushSettings(forLocalUserID: userID, with: navController)
			}
			else {
				self.currentLocalUserID = localUser.uuid
			}
		}
	}

	func showActivityView(){
		
		let vc = UIHostingController(rootView: ContentView())
		let navController =  UINavigationController(rootViewController: vc)
		vc.rootView.nav = navController
		UIApplication.shared.setRootVC(navController)
		
		ZDCManager.zdc().uiTools?.pushActivityView(forLocalUserID: nil, with: navController)
	}
	
	

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: Utility Functions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	

	class func checkForCameraAvailable(viewController:UIViewController!,
												  completion: @escaping (Bool) -> ()) {
		
		let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
		
		switch photoAuthorizationStatus {
		case .authorized:
			completion(true)
			break
			
		case .notDetermined:
			PHPhotoLibrary.requestAuthorization({
				(newStatus) in
				if newStatus ==  PHAuthorizationStatus.authorized {
					completion(true)
				}
				else
				{
					completion(false)
				}
			})
			
		case .restricted:
			let alert = UIAlertController(title: "Can not add Photo",
													message: "Access to Photo Library is restricted",
													preferredStyle: .alert)
			
			let okAction = UIAlertAction(title: "OK", style: .default) { (alert: UIAlertAction!) -> Void in
				completion(false)
			}
			alert.addAction(okAction)
			viewController.present(alert, animated: true, completion:nil)
			
			
		case .denied:
			let alert = UIAlertController(title: "Photo Access Off",
													message: "Change your settings to allow access to Photos",
													preferredStyle: .alert)
			
			let okAction = UIAlertAction(title: "Change Settings", style: .default) { (alert: UIAlertAction!) -> Void in
				
				UIApplication.shared.open(URL.init(string: UIApplication.openSettingsURLString)!,
												  options:  [:],
												  completionHandler: { (complete) in
													completion(false)
				})
			}
			
			let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (alert: UIAlertAction!) -> Void in
				completion(false)
			}
			
			alert.addAction(okAction)
			alert.addAction(cancelAction)
			viewController.present(alert, animated: true, completion:nil)
			
			completion(false)
			
		@unknown default:
			break;
		}
	}
}

