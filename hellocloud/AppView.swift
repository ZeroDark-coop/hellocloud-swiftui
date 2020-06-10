//
//  AppView.swift
//  sample1
//
//  Created by Vincent Moscaritolo on 6/2/20.
//  Copyright © 2020 Zerodark.coop. All rights reserved.
//

import SwiftUI

 

struct AppView: View {
	
	@Binding var showMenu: Bool
 
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
			ZStack(alignment: .bottomLeading) {
			
				// this is a good place to put any TabView and or your own custom stuff
			 Text("Put your App Here")
 
			}
			.simultaneousGesture(drag)
		
	}
	
}
