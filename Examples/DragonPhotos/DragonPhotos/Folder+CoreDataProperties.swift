//
//  Folder+CoreDataProperties.swift
//  DragonPhotos
//
//  Created by Nevyn Bengtsson on 2015-12-13.
//  Copyright © 2015 ThirdCog. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Folder {

    @NSManaged var entries: NSMutableOrderedSet!

}
