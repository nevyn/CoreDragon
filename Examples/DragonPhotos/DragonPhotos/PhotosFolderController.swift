//
//  ViewController.swift
//  DragonPhotos
//
//  Created by Nevyn Bengtsson on 2015-12-12.
//  Copyright © 2015 ThirdCog. All rights reserved.
//

import UIKit
import CoreData

/* This view controller presents a user-defined list of photos. Photos can be imported
	from the camera roll. They can then be organized into folders by dragging and dropping.
	
	 Three pieces of code allow these photos to be dragged. They are marked drag1, drag2 and drag3.
	 
	 Three pieces of code allow these photos to be dropped, to put them into folders. They
	 are marked drop1, drop2 and drop3. */
class PhotosFolderController: UICollectionViewController, NSFetchedResultsControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, DragonDelegate {
	
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
			
			// drag1: Allow any PhotoCell to be dragged, and have this view controller handle it.
			DragonController.sharedController().registerDragSource(cell, delegate: self)
			return cell
		} else if let folder = entry as? Folder {
			let cell = self.collectionView!.dequeueReusableCellWithReuseIdentifier("FolderCell", forIndexPath: indexPath) as! FolderCell
			cell.label.text = "\(folder.entries!.count) photos"
			
			// drag2: Same for FolderCells.
			DragonController.sharedController().registerDragSource(cell, delegate: self)
			return cell
		} else {
			abort()
		}
	}
	
	// drag3: The user has initiated a drag from a specific cell. Handle it.
	func beginDragOperation(drag: DragonInfo, fromView draggable: UIView) {
		let indexPath = self.collectionView!.indexPathForCell(draggable as! UICollectionViewCell)!
		let entry = folder.entries![indexPath.item]
		if let photo = entry as? Photo {
			// The only required thing to do in this method is to put something on the
			// pasteboard. Here we put an image on there.
			drag.pasteboard.image = photo.image
		}
	}

}

class PhotoCell : UICollectionViewCell {
	@IBOutlet var imageView : UIImageView!
}

class FolderCell : UICollectionViewCell {
	@IBOutlet var label : UILabel!
}

