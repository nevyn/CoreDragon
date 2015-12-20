//
//  PhotoViewController.swift
//  DragonPhotos
//
//  Created by Nevyn Bengtsson on 2015-12-20.
//  Copyright © 2015 ThirdCog. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {
	@IBOutlet var imageView : UIImageView! = nil
	private var _image : UIImage?
	var image : UIImage? {
		set {
			if let view = self.imageView {
				view.image = newValue
			}
			_image = newValue
		}
		get {
			return _image
		}
	}
	override func viewDidLoad() {
		self.imageView.image = _image
	}
	
	@IBAction func dismiss(sender: AnyObject)
	{
		self.dismissViewControllerAnimated(true, completion: nil)
	}
}
