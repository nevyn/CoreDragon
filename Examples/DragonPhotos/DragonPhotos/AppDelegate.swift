//
//  AppDelegate.swift
//  DragonPhotos
//
//  Created by Nevyn Bengtsson on 2015-12-12.
//  Copyright © 2015 ThirdCog. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	var model = PhotosModel()

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		
		DragonController.sharedController().enableLongPressDraggingInWindow(self.window!)
		
		let nav = self.window!.rootViewController as! UINavigationController
		let root = nav.viewControllers[0] as! PhotosFolderController
		root.folder = Folder.rootFolder(inContext: model.managedObjectContext)
		return true
	}
	
	func applicationWillResignActive(application: UIApplication) {
		model.saveContext()
	}
	func applicationDidEnterBackground(application: UIApplication) {
		model.saveContext()
	}
	func applicationWillTerminate(application: UIApplication) {
		model.saveContext()
	}
}

