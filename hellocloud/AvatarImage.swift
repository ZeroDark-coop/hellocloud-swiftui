 //
//  AvatarImage.swift
//  hellocloud
//
//  Created by Vincent Moscaritolo on 6/1/20.
//  Copyright © 2020 Zerodark.coop. All rights reserved.
//

import SwiftUI
import ZeroDarkCloud


class AvatarLoader: ObservableObject {
	
	@Published var image: UIImage?
	
	func load(userID: String) {
		
		let zdc :ZeroDarkCloud = ZDCManager.zdc()
		let databaseConnection :YapDatabaseConnection = ZDCManager.zdc().databaseManager!.uiDatabaseConnection
		
		image = zdc.imageManager!.defaultUserAvatar()
		
		databaseConnection.read { (transaction) in
			
			guard let user = transaction.localUser(id: userID) else {
				fatalError("user \(userID) not found !")
			}
			
			let preFetch = {(fetchedImage: UIImage?, willFetch: Bool) in
				if((fetchedImage) != nil) {
					self.image = fetchedImage!
				}
			}
			
			let postFetch = {(fetchedImage: UIImage?, error: Error?) in
				if((fetchedImage) != nil){
					self.image = fetchedImage!
					
				}
			}
			
			zdc.imageManager!.fetchUserAvatar( user,
														  with: nil,
														  preFetch: preFetch,
														  postFetch: postFetch)
		}
		
	}
	
}



struct AvatarImage: View {
	
	@ObservedObject private var avatarLoader = AvatarLoader()
	private var size: CGFloat;
	
	init(userID :String, size:CGFloat? = nil) {
		self.size = size ?? 32
		self.avatarLoader.load(userID: userID)
	}
	
	
	var body: some View {
		return Image(uiImage:self.avatarLoader.image!)
			.renderingMode(.original)
			.resizable()
			.frame(width: size, height: size)
			.clipShape(Circle())
	}
}
