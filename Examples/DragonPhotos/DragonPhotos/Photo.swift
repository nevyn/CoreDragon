//
//  Photo.swift
//  DragonPhotos
//
//  Created by Nevyn Bengtsson on 2015-12-13.
//  Copyright © 2015 ThirdCog. All rights reserved.
//

import Foundation
import CoreData


class Photo: Entry {

	var image : UIImage? {
		get {
			if let data = self.jpgData {
				return UIImage(data: data)
			}
			return nil
		}
		set {
			if let image = newValue {
				self.jpgData = UIImageJPEGRepresentation(image, 0.8)
			} else {
				self.jpgData = nil
			}
		}
	}

}
