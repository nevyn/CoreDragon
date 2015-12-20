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
		
		// DROPPING: Drop a photo onto the background to reorder it, or if it's a new photo,
		// insert it into this folder.
		DragonController.sharedController().registerDropTarget(self.collectionView!, delegate: self)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "draggingEnded", name: DragonDragOperationStoppedNotificationName, object: nil)
	}
	
	override func viewWillAppear(animated: Bool) {
		self.collectionView?.reloadData()
	}
	
	// MARK: Adding photos
	
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
	
	// MARK: Collection view
	
	override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		return self.folder.entries!.count
	}
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
	{
		let entry = folder.entries![indexPath.item]
		let entryCell : EntryCell
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
		entryCell.representedIndex = indexPath.item
		
		// DRAGGING: We register all photos and folders as a drag source, so we can pick them up.
		DragonController.sharedController().registerDragSource(entryCell, delegate: self)
		
		// DROPPING: We also register all photos and folders as a drop source, so we can drop
		// things on them to group them together into folders.
		DragonController.sharedController().registerDropTarget(entryCell, delegate: self)
		
		return entryCell
	}
	
	// MARK: Dragging
	
	// Pasteboard type for a core data reference.
	let UTEntryReference = "eu.thirdcog.dragonphotos.entryReference"
	
	// The user has initiated a drag from a specific cell. Handle it.
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
	
	// MARK: Dropping
	
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
			if droppable == self.collectionView! {
				return true
			}
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
			
			// First: Determine what's coming in.
			let incoming : Entry
			if let droppedEntry = self.entryFromPasteboard(drag.pasteboard) {
				// If it's an existing photo or folder from inside the app, we will move it.
				incoming = droppedEntry
			} else if let droppedImage = drag.pasteboard.image {
				// If it's a photo, create a new one and insert it.
				let newPhoto = NSEntityDescription.insertNewObjectForEntityForName("Photo", inManagedObjectContext: self.folder.managedObjectContext!) as! Photo
				newPhoto.jpgData = UIImageJPEGRepresentation(droppedImage, 0.8)
				incoming = newPhoto
			} else { abort() }
			
			// Then: Determine where we're going to put it.
			let destination : Folder
			if let cell = droppable as? UICollectionViewCell,
			   let indexPath = self.collectionView!.indexPathForCell(cell) {
				// Did we drop onto a cell?
				let destinationEntry = self.folder.entries![indexPath.item]
				if let toFolder = destinationEntry as? Folder {
					// If we're dropping on a folder, insert the photo into that folder.
					destination = toFolder
				} else if let toPhoto = destinationEntry as? Photo {
					// If we're dropping on a photo, create a new folder with the existing photo and the new photo.
					let newFolder = NSEntityDescription.insertNewObjectForEntityForName("Folder", inManagedObjectContext: self.folder.managedObjectContext!) as! Folder
					newFolder.mutableOrderedSetValueForKey("entries").addObjectsFromArray([toPhoto])
					self.folder.mutableOrderedSetValueForKey("entries").insertObject(newFolder, atIndex: indexPath.item)
					destination = newFolder
				} else { abort() }
				self.collectionView!.reloadItemsAtIndexPaths([indexPath])
			} else {
				// Dropped onto background.
				destination = self.folder
			}
			
			// Before performing move/copy: schedule the correct animation.
			if destination == self.folder {
				// We're moving into this VC's folder.
				
				if incoming.parentFolder != self.folder {
					// It wasn't in this folder before.
					self.collectionView!.insertItemsAtIndexPaths([self.dropInsertionIndex!])
				} else {
					// It was in this folder before.
					let sourceIndex = self.folder.entries.indexOfObject(incoming)
					let indexPath = NSIndexPath(forItem: sourceIndex, inSection: 0)
					
					// If we're moving it to a higher index, the new index will be 1 too high.
					if sourceIndex < self.dropInsertionIndex!.item {
						self.dropInsertionIndex = NSIndexPath(forItem: self.dropInsertionIndex!.item-1, inSection: 0)
					}

					self.collectionView!.moveItemAtIndexPath(indexPath, toIndexPath: self.dropInsertionIndex!)
				}
			} else {
				// We're moving to some other folder.
				if incoming.parentFolder == self.folder {
					// and moving out of this one. Animate its deletion.
					let sourceIndex = self.folder.entries.indexOfObject(incoming)
					let indexPath = NSIndexPath(forItem: sourceIndex, inSection: 0)
					self.collectionView?.deleteItemsAtIndexPaths([indexPath])
					
					// and make sure to hide it so it doesn't fade in after dragging concludes.
					self.collectionView?.cellForItemAtIndexPath(indexPath)?.hidden = true
				} else {
					// Neither source folder nor destination folder are represented by this VC
				}
			}
			
			// Finally: Perform move/copy of 'incoming' into 'destination'.
			if let destinationIndexPath = self.dropInsertionIndex {
				if destination.entries.containsObject(incoming) {
					destination.mutableOrderedSetValueForKey("entries").removeObject(incoming)
				}
				destination.mutableOrderedSetValueForKey("entries").insertObject(incoming, atIndex: destinationIndexPath.item)
			} else {
				incoming.parentFolder = destination
			}
			

		}) { (success) -> Void in
			
		}
	}
	
	var dropInsertionIndex : NSIndexPath?
	var dropInsertionView : UIView?
	func dropTarget(droppable: UIView, updateHighlight highlightContainer: UIView, forDrag drag: DragonInfo, atPoint hoveringPoint: CGPoint) {
		if droppable != self.collectionView {
			dropInsertionIndex = nil
			dropInsertionView?.removeFromSuperview()
			dropInsertionView = nil
			return
		}
		
		// This is potentially a reordering operation. Figure out the index path
		// for where we would want to put this new item.
		
		// Find all the insertion points as CGPoints in the collection view's coordinate space
		let cells = self.collectionView!.visibleCells().sort { (a, b) -> Bool in
			return self.collectionView!.indexPathForCell(a)!.compare(self.collectionView!.indexPathForCell(b)!) == .OrderedAscending
		}
		var heights : [CGFloat] = []
		var centerPointsOfEdges = cells.map { (cell) -> CGPoint in
			var leftEdgeFrame = cell.frame
			leftEdgeFrame.size.width = 0
			heights.append(leftEdgeFrame.size.height)
			return CGPoint(x: leftEdgeFrame.midX, y: leftEdgeFrame.midY)
		}
		if centerPointsOfEdges.count == 0 {
			// This folder is empty. Use the normal highlight and insert at the beginning.
			highlightContainer.hidden = false
			centerPointsOfEdges.append(.zero)
			heights.append(100)
		} else {
			// This folder is not empty. Use a custom highlight, and add an extra point at the end for tail insertion
			highlightContainer.hidden = true
			var rightmostEdgeFrame = cells.last!.frame
			rightmostEdgeFrame.origin.x += rightmostEdgeFrame.size.width
			rightmostEdgeFrame.size.width = 0
			centerPointsOfEdges.append(CGPoint(x: rightmostEdgeFrame.midX, y: rightmostEdgeFrame.midY))
			heights.append(rightmostEdgeFrame.size.height)
		}
		
		var bestDistanceSoFar : CGFloat = 1e100
		let bestIndex = centerPointsOfEdges.reduce(0) { (previousBestIndex, point) -> Int in
			let diff = CGPoint(x: hoveringPoint.x - point.x, y: hoveringPoint.y - point.y)
			let distance = sqrt(diff.x*diff.x + diff.y*diff.y)
			if distance < bestDistanceSoFar {
				bestDistanceSoFar = distance
				return centerPointsOfEdges.indexOf(point)!
			} else {
				return previousBestIndex
			}
		}
		dropInsertionIndex = NSIndexPath(forItem: bestIndex, inSection: 0)
		
		let size = CGSize(width: 5, height: heights[bestIndex])
		var topLeft = centerPointsOfEdges[bestIndex]
		topLeft.x -= size.width/2; topLeft.y -= size.height/2
		
		let insertionFrame = CGRect(origin: topLeft, size: size)
		if let view = dropInsertionView {
			view.frame = insertionFrame
		} else {
			let view = UIView(frame: insertionFrame)
			view.backgroundColor = .blueColor()
			dropInsertionView = view
			self.collectionView!.addSubview(view)
		}
	}
	
	func draggingEnded() {
		dropInsertionView?.removeFromSuperview()
		dropInsertionView = nil
	}
	
	// MARK: Springloading
	
	func dropTarget(droppable: UIView, shouldSpringload drag: DragonInfo) -> Bool {
		guard let cell = droppable as? EntryCell,
			  let _ = folder.entries![cell.representedIndex] as? Folder
		else {
			return false
		}
		return true
	}
	
	func dropTarget(droppable: UIView, springload drag: DragonInfo, atPoint p: CGPoint) {
		guard let cell = droppable as? UICollectionViewCell,
			  let thisIndexPath = self.collectionView!.indexPathForCell(cell),
			  let _ = folder.entries![thisIndexPath.item] as? Folder
		else {
			abort()
		}
		self.collectionView!.selectItemAtIndexPath(thisIndexPath, animated: true, scrollPosition: .None)
		self.performSegueWithIdentifier("enterFolder", sender: nil)
	}
	
	// MARK: Segues
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let dest = segue.destinationViewController as? PhotosFolderController {
			let enteredFolder = folder.entries![self.collectionView!.indexPathsForSelectedItems()!.first!.item] as! Folder
			dest.folder = enteredFolder
		} else if let dest = segue.destinationViewController as? PhotoViewController {
			let enteredPhoto = folder.entries![self.collectionView!.indexPathsForSelectedItems()!.first!.item] as! Photo
			dest.image = enteredPhoto.image!
		}
	}
}

class EntryCell : UICollectionViewCell
{
	var representedIndex: Int = 0
}

class PhotoCell : EntryCell {
	@IBOutlet var imageView : UIImageView!
}

class FolderCell : EntryCell {
	@IBOutlet var label : UILabel!
}

