//
//  Folder.swift
//  DragonPhotos
//
//  Created by Nevyn Bengtsson on 2015-12-13.
//  Copyright © 2015 ThirdCog. All rights reserved.
//

import Foundation
import CoreData


class Folder: NSManagedObject {

	class func rootFolder(inContext context: NSManagedObjectContext) -> Folder {
		let req = NSFetchRequest(entityName: "Folder")
		req.predicate = NSPredicate(format: "parentFolder = nil", argumentArray: nil)
		
		let res = try! context.executeFetchRequest(req)
		if res.count > 0 {
			return res[0] as! Folder
		}
		
		let new = NSEntityDescription.insertNewObjectForEntityForName("Folder", inManagedObjectContext: context) as! Folder
		
		return new
	}
}
