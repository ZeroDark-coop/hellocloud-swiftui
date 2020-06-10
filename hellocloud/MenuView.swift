////MenuView.swift


import SwiftUI

import ZeroDarkCloud

//struct ListSeparatorStyle: ViewModifier {
//
//    let style: UITableViewCell.SeparatorStyle
//
//    func body(content: Content) -> some View {
//        content
//            .onAppear() {
//                UITableView.appearance().separatorStyle = self.style
//            }
//    }
//}
//
//extension View {
//
//    func listSeparatorStyle(style: UITableViewCell.SeparatorStyle) -> some View {
//        ModifiedContent(content: self, modifier: ListSeparatorStyle(style: style))
//    }
//}

struct ListHeader: View {
	
	@Binding var showMenu: Bool
	
	var body: some View {
		HStack {
			Text("ACCOUNTS")
				.font(.system(size: 14, weight: .semibold, design: .rounded))
				.multilineTextAlignment(.leading)
				.foregroundColor(.secondary)
			Spacer()
			Button(action: {
				AppDelegate.sharedInstance().showActivationView(canDismissWithoutNewAccount:true)
			}) {
				Image(systemName: "plus.circle")
					.font(.system(size: 20, weight: .light))
			}
		}
	}
}

 
struct MenuView: View {
	
	let  	zdc :ZeroDarkCloud = ZDCManager.zdc()
	let  	databaseConnection :YapDatabaseConnection = ZDCManager.zdc().databaseManager!.uiDatabaseConnection
	
	@Binding var showMenu: Bool
	
	@State var sortedUsers: [ZDCUserDisplay] = []
	@State var showingAlert = false
	
	@State var userIDToDelete: [String] = []
	
	var body: some View {
		
		List {
			Section(header: ListHeader(showMenu: $showMenu))
			{
				ForEach(sortedUsers, id: \.userID) { info in
					
					Button(action: {
						AppDelegate.sharedInstance().currentLocalUserID = info.userID
						
					}) {
						
						HStack(spacing: 10) {
							AvatarImage(userID: info.userID, size: 32)
							Text("\(info.displayName)")
								.allowsTightening(true)
								.lineLimit(1)
								.minimumScaleFactor(0.7)
							
							Spacer()
							
							if (info.userID == AppDelegate.sharedInstance().currentLocalUserID) {
								Image(systemName: "checkmark")
									.foregroundColor(.accentColor)
							} else {
								Image(systemName: "chevron.right")
									.foregroundColor(.secondary)
							}
						}
					}
				}
					
				.onDelete { indices in
					
					self.userIDToDelete = []
					
					indices.forEach{ offset in
						
						let info: ZDCUserDisplay = self.sortedUsers[offset]
						self.userIDToDelete.append(info.userID)
					}
					self.showingAlert = true
					
				}
				
				
			}
			
			Section(header:
				
				Text("OPTIONS")
					.font(.system(size: 14, weight: .semibold, design: .rounded))
					.multilineTextAlignment(.leading)
					.foregroundColor(.secondary)
			) {
				
				Button(action: {
					self.showSettingView()
				}) {
					HStack(spacing: 10){
						Image(systemName: "gear")
							.foregroundColor(.accentColor)
						Text("Settings")
					}
				}
				
				Button(action: {
					self.showActivityView()
				}) {
					HStack(spacing: 10){
						Image(systemName: "cloud.bolt")
							.foregroundColor(.accentColor)
						Text("Activity Monitor")
					}
				}
				
				
			}
		}
			
			//		.listSeparatorStyle(style: .none)
			
			.onAppear {
				
				UITableView.appearance().tableFooterView = UIView()
				UITableView.appearance().separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
				
				// update the array of localUsers
				self.databaseConnection.read { (transaction) in
					let localUsers = self.zdc.localUserManager!.allLocalUsers(transaction)
					self.sortedUsers = self.zdc.userManager!.sortedUnambiguousNames(for: localUsers)
				}
				
		}
		.actionSheet(isPresented: $showingAlert) {
			
			let matchingInfo = sortedUsers.filter{ $0.userID == userIDToDelete.first }
			let localUserID  = matchingInfo.first!.userID
			
			var localUser: ZDCLocalUser? = nil
			databaseConnection.read { (transaction) in
				
				localUser = transaction.localUser(id: localUserID)
			}
			
			if let localUser = localUser {
				
				let titleFrmt = NSLocalizedString( "Delete user \"%@\" from this device?",
															  comment: "Delete user prompt")
				
				let title = String(format: titleFrmt, localUser.displayName)
				
				let warningMessage = NSLocalizedString("""
												You have not backed up your access key!\n
												If you delete this user you might lose access to your data!
												We recommend you backup your access key before proceeding.
												""",
																	comment: "Delete user warning");
				
				let message = ( localUser.hasCompletedSetup
					&& !localUser.hasBackedUpAccessCode) ? warningMessage : nil
				
				if let message = message {
					
					return
						ActionSheet(title: Text("\(title)"),
										message: Text("\(message)"),
										buttons: [.destructive((Text("Delete")),
																	  action: {
																		self.deleteUser(userID: localUserID)
										}),
													 .default(Text("Backup Access Key"),
																 action: {
																	self.backupKey(forUserID: localUserID)
													}),
													 .cancel({
														self.userIDToDelete = []
													})])
					
				}
				else
				{
					return ActionSheet(title: Text("\(title)"),
											 buttons: [.destructive((Text("Delete")),
																			action: {
																				self.deleteUser(userID: localUserID)
											}),
														  .cancel({
															self.userIDToDelete = []
														})])
				}
			}
				
			else {
				return
					ActionSheet(title: Text("Internal Error"))
			}
		}
	}
	
	
	func backupKey(forUserID:String!)
	{
		AppDelegate.sharedInstance().pushBackupView(userID: forUserID)
	}
	
	
	func deleteUser(userID:String!)
	{
		AppDelegate.sharedInstance().deleteUserID(userID: userID,
																completion: { (success) in
																	AppDelegate.sharedInstance().currentLocalUserID = nil
																	
		})
		
	}
	
	func showActivityView() {
		AppDelegate.sharedInstance().showActivityView()
	}
	
	func showSettingView() {
		AppDelegate.sharedInstance().pushSettinsView()
	}
}




