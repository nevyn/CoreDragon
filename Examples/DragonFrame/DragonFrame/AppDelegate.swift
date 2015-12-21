//
//  AppDelegate.swift
//  DragonFrame
//
//  Created by Nevyn Bengtsson on 2015-12-20.
//  Copyright © 2015 ThirdCog. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		
		// When the application starts, we enable CoreDragon and drag-and-drop behavior
		// by telling DragonController to use the long press gesture in our main
		// application window. This means that when the user long-presses on an object
		// that she wishes to move or copy, a CoreDragon dragging operation will start.
		// A custom gesture can also be used: see DragonController.h for details.
		DragonController.sharedController().enableLongPressDraggingInWindow(self.window!)

		return true
	}


}

