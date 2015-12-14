//
//  ViewController.swift
//  DragonPhotos
//
//  Created by Nevyn Bengtsson on 2015-12-12.
//  Copyright © 2015 ThirdCog. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices

/* This view controller presents a user-defined list of photos. Photos can be imported
	from the camera roll. They can then be organized into folders by dragging and dropping.
	
	 All comments below are pertaining to dragging and dropping, so just look for the
	 green text. */
class PhotosFolderController: UICollectionViewController, NSFetchedResultsControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, DragonDelegate, DragonDropDelegate {
	
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
		let entryCell : UICollectionViewCell
		if let photo = entry as? Photo {
			let cell = self.collectionView!.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
			entryCell = cell
			cell.imageView.image = photo.image
		} else if let folder = entry as? Folder {
			let cell = self.collectionView!.dequeueReusableCellWithReuseIdentifier("FolderCell", forIndexPath: indexPath) as! FolderCell
			entryCell = cell
			cell.label.text = "\(folder.entries!.count) photos"
		} else {
			abort()
		}
		
		// DRAGGING: We register all photos and folders as a drag source, so we can pick them up.
		DragonController.sharedController().registerDragSource(entryCell, delegate: self)
		
		// DROPPING: We also register all photos and folders as a drop source, so we can drop
		// things on them to group them together into folders.
		DragonController.sharedController().registerDropTarget(entryCell, delegate: self)
		
		return entryCell
	}
	
	// DRAGGING: The user has initiated a drag from a specific cell. Handle it.
	func beginDragOperation(drag: DragonInfo, fromView draggable: UIView) {
		let indexPath = self.collectionView!.indexPathForCell(draggable as! UICollectionViewCell)!
		let entry = folder.entries![indexPath.item]
		if let photo = entry as? Photo {
			// The only required thing to do in this method is to put something on the
			// pasteboard. Here we put an image on there.
			drag.pasteboard.image = photo.image
		}
	}
	
	func dropTarget(droppable: UIView, canAcceptDrag drag: DragonInfo) -> Bool {
		// Is there something image-like on the pasteboard?
		return drag.pasteboard.pasteboardTypes().contains({ (str) -> Bool in
			return UIPasteboardTypeListImage.containsObject(str)
		})
	}
	
	func dropTarget(droppable: UIView, acceptDrag drag: DragonInfo, atPoint p: CGPoint) {
		let indexPath = self.collectionView!.indexPathForCell(droppable as! UICollectionViewCell)!
		let entry = folder.entries![indexPath.item]
		// This is where we will take the photo or folder from the pasteboard and
		// put it in the dropped folder, or create one if it was dropped on a photo.
	}

}

class PhotoCell : UICollectionViewCell {
	@IBOutlet var imageView : UIImageView!
}

class FolderCell : UICollectionViewCell {
	@IBOutlet var label : UILabel!
}

