//
//  CMGlossary+CoreDataProperties.swift
//  
//
//  Created by Jovito Royeca on 06/08/2017.
//
//

import Foundation
import CoreData


extension CMGlossary {

    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest<CMGlossary>(entityName: "CMGlossary") as! NSFetchRequest<NSFetchRequestResult>
    }

    @NSManaged public var term: String?
    @NSManaged public var termSection: String?
    @NSManaged public var definition: String?

}
