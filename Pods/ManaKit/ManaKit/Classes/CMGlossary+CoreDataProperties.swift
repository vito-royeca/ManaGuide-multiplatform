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

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CMGlossary> {
        return NSFetchRequest<CMGlossary>(entityName: "CMGlossary")
    }

    @NSManaged public var term: String?
    @NSManaged public var termSection: String?
    @NSManaged public var definition: String?

}
