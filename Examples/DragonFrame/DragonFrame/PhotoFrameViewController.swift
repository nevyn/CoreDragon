//
//  FirstViewController.swift
//  DragonFrame
//
//  Created by Nevyn Bengtsson on 2015-12-20.
//  Copyright © 2015 ThirdCog. All rights reserved.
//

import UIKit

class PhotoFrameViewController: UIViewController, DragonDropDelegate {
	
	@IBOutlet var imageView : UIImageView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Load image from last run.
		imageView.image = self.image
		
		// The user may drop things on the image view.
		// This view controller will be the delegate to determine if and how
		// drop operations will be handled.
		DragonController.sharedController().registerDropTarget(self.imageView, delegate: self)
	}
	
	// When a dragging operation starts, this method is called for each drop target
	// that this view controller is responsible for, to see if the drop target
	// is potentially able to accept the contents of that drag'n'drop.
	func dropTarget(droppable: UIView, canAcceptDrag drag: DragonInfo) -> Bool {
		// Is there something image-like on the pasteboard? Then accept it.
		if drag.pasteboard.pasteboardTypes().contains({ (str) -> Bool in
			return UIPasteboardTypeListImage.containsObject(str)
		}) {
			return true
		}
		
		return false
	}
	
	// Once the user drops the item on a drop target view, this method is responsible
	// for accepting the data and handling it.
	func dropTarget(droppable: UIView, acceptDrag drag: DragonInfo, atPoint p: CGPoint) {
		if let image = drag.pasteboard.image {
			// We handle it by setting the main image view's image to the one 
			// that the user dropped, and ...
			self.imageView.image = image
			
			// ... also saving it to disk for next time.
			self.image = image
		}
	}
	
	// Helpers for loading/saving images from disk
	var imageURL : NSURL {
		get {
			let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
			return NSURL.fileURLWithPath(documentsPath).URLByAppendingPathComponent("image.jpg")
		}
	}
	var image : UIImage? {
		get {
			return UIImage(contentsOfFile: self.imageURL.path!)
		}
		set {
			if let image = newValue {
				UIImageJPEGRepresentation(image, 0.8)?.writeToURL(self.imageURL, atomically: false)
			}
		}
	}
}