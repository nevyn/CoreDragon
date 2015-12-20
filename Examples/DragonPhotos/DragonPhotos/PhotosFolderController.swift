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
		folder.mutableOrderedSetValueForKey("entries").addObject(photo)
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
	
	// Pasteboard type for a core data reference.
	let UTEntryReference = "eu.thirdcog.dragonphotos.entryReference"
	
	// DRAGGING: The user has initiated a drag from a specific cell. Handle it.
	func beginDragOperation(drag: DragonInfo, fromView draggable: UIView) {
		let indexPath = self.collectionView!.indexPathForCell(draggable as! UICollectionViewCell)!
		let entry = folder.entries![indexPath.item]
		if let photo = entry as? Photo {
			// The only required thing to do in this method is to put something on the
			// pasteboard. We want to put two things on the pasteboard:
			let item : [String: AnyObject] = [
				// The first is the actual image data, so that we can drag it to
				// other applications.
				kUTTypeJPEG as String: photo.jpgData!,
				
				// The second type is a reference to the database object, so that
				// if we drag it within the application, we can move it around in
				// the database without looking it up by jpeg data.
				UTEntryReference: entry.objectID.URIRepresentation().dataRepresentation
			]
			drag.pasteboard.items = [item]
		}
	}
	
	// Figures out if there's an entry reference in the pasteboard, and if so, returns the CD entry.
	func entryFromPasteboard(pasteboard: UIPasteboard) -> Entry? {
		if !pasteboard.containsPasteboardTypes([UTEntryReference]) {
			return nil
		}
		
		guard
			let urlData = pasteboard.valueForPasteboardType(UTEntryReference) as? NSData
		else {
			return nil
		}
		
		let url = NSURL(dataRepresentation: urlData, relativeToURL: nil)
		guard
			  let moc = self.folder.managedObjectContext,
			  let psc = moc.persistentStoreCoordinator,
			  let objectId = psc.managedObjectIDForURIRepresentation(url),
			  let entry = (try? moc.existingObjectWithID(objectId)) as? Entry
		else {
			return nil
		}
		
		return entry
	}
	
	func dropTarget(droppable: UIView, canAcceptDrag drag: DragonInfo) -> Bool {
		// Is there a reference to an object from within this app?
		if let entry = entryFromPasteboard(drag.pasteboard) {
			// if the droppable isn't in the table view yet, 'entry' cannot be 'thisEntry'
			guard let thisIndexPath = self.collectionView!.indexPathForCell(droppable as! UICollectionViewCell) else {
				return true
			}
			let thisEntry = folder.entries![thisIndexPath.item] as! Entry
			// You can't drop an entry on itself.
			return entry != thisEntry
		}
		
		// Is there something image-like on the pasteboard? Then accept it and just copy it in.
		if drag.pasteboard.pasteboardTypes().contains({ (str) -> Bool in
			return UIPasteboardTypeListImage.containsObject(str)
		}) {
			return true
		}
		
		return false
	}
	
	func dropTarget(droppable: UIView, acceptDrag drag: DragonInfo, atPoint p: CGPoint) {
		// This is where we will take the photo or folder from the pasteboard and
		// put it in the dropped folder, or create one if it was dropped on a photo.
		
		self.collectionView!.performBatchUpdates({ () -> Void in
			let indexPath = self.collectionView!.indexPathForCell(droppable as! UICollectionViewCell)!
			let destinationEntry = self.folder.entries![indexPath.item]
			
			// Determine what's coming in.
			let incoming : Entry
			if let droppedEntry = self.entryFromPasteboard(drag.pasteboard) {
				// If it's an existing photo or folder from inside the app, we will move it.
				incoming = droppedEntry
				let sourceIndex = self.folder.entries.indexOfObject(droppedEntry)
				if sourceIndex != NSNotFound {
					self.collectionView?.deleteItemsAtIndexPaths([NSIndexPath(forItem: sourceIndex, inSection: indexPath.section)])
				}
			} else if let droppedImage = drag.pasteboard.image {
				// If it's a photo, create a new one and insert it.
				let newPhoto = NSEntityDescription.insertNewObjectForEntityForName("Photo", inManagedObjectContext: self.folder.managedObjectContext!) as! Photo
				newPhoto.jpgData = UIImageJPEGRepresentation(droppedImage, 0.8)
				incoming = newPhoto
			} else { abort() }
			
			// Determine where we're going to put it.
			if let toFolder = destinationEntry as? Folder {
				// If we're dropping on a folder, insert the photo into that folder.
				incoming.parentFolder = toFolder
			} else if let toPhoto = destinationEntry as? Photo {
				// If we're dropping on a photo, create a new folder with the existing photo and the new photo.
				let newFolder = NSEntityDescription.insertNewObjectForEntityForName("Folder", inManagedObjectContext: self.folder.managedObjectContext!) as! Folder
				newFolder.mutableOrderedSetValueForKey("entries").addObjectsFromArray([toPhoto, incoming])
				self.folder.mutableOrderedSetValueForKey("entries").insertObject(newFolder, atIndex: indexPath.item)
			}
			
			self.collectionView!.reloadItemsAtIndexPaths([indexPath])
		}) { (success) -> Void in
			
		}
	}

}

class PhotoCell : UICollectionViewCell {
	@IBOutlet var imageView : UIImageView!
}

class FolderCell : UICollectionViewCell {
	@IBOutlet var label : UILabel!
}

