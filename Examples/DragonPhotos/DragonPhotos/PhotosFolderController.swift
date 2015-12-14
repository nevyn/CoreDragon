//
//  ViewController.swift
//  DragonPhotos
//
//  Created by Nevyn Bengtsson on 2015-12-12.
//  Copyright © 2015 ThirdCog. All rights reserved.
//

import UIKit
import CoreData

class PhotosFolderController: UICollectionViewController, NSFetchedResultsControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	var folder : Folder!
	let imagePicker = UIImagePickerController()
	
	override func viewDidLoad() {
		super.viewDidLoad()		
		imagePicker.delegate = self
	}
	
	@IBAction func addPhoto(sender: UIBarButtonItem)
	{
		imagePicker.modalPresentationStyle = .Popover
		presentViewController(imagePicker, animated: true, completion: nil)
		imagePicker.popoverPresentationController?.barButtonItem = sender
	}
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
	{
		let image = info[UIImagePickerControllerOriginalImage] as! UIImage
		
		let photo = NSEntityDescription.insertNewObjectForEntityForName("Photo", inManagedObjectContext: folder.managedObjectContext!) as! Photo
		photo.image = image
		folder.entries.addObject(photo)
		self.collectionView!.reloadData()
		
		dismissViewControllerAnimated(true, completion: nil)
	}
	func imagePickerControllerDidCancel(picker: UIImagePickerController) {
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		return self.folder.entries!.count
	}
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
	{
		let entry = folder.entries![indexPath.item]
		if let photo = entry as? Photo {
			let cell = self.collectionView!.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
			cell.imageView.image = photo.image
			return cell
		} else if let folder = entry as? Folder {
			let cell = self.collectionView!.dequeueReusableCellWithReuseIdentifier("FolderCell", forIndexPath: indexPath) as! FolderCell
			cell.label.text = "\(folder.entries!.count) photos"
			return cell
		} else {
			abort()
		}
	}
}

class PhotoCell : UICollectionViewCell {
	@IBOutlet var imageView : UIImageView!
}

class FolderCell : UICollectionViewCell {
	@IBOutlet var label : UILabel!
}

