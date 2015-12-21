//
//  SecondViewController.swift
//  DragonFrame
//
//  Created by Nevyn Bengtsson on 2015-12-20.
//  Copyright © 2015 ThirdCog. All rights reserved.
//

import UIKit

class ExamplePhotosController: UIViewController, DragonDelegate {

	@IBOutlet var first : UIImageView!
	@IBOutlet var second : UIImageView!
	@IBOutlet var third : UIImageView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		first.image = UIImage(named: "a")
		second.image = UIImage(named: "b")
		third.image = UIImage(named: "c")
		
		// The user can grab any one of the images and start dragging them.
		DragonController.sharedController().registerDragSource(first, delegate: self)
		DragonController.sharedController().registerDragSource(second, delegate: self)
		DragonController.sharedController().registerDragSource(third, delegate: self)
	}
	
	func beginDragOperation(drag: DragonInfo, fromView draggable: UIView) {
		// When she does, we take the image and put it on the pasteboard.
		drag.pasteboard.image = (draggable as! UIImageView).image
	}
}

