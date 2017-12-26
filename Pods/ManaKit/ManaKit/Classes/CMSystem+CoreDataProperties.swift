//
//  CMSystem+CoreDataProperties.swift
//  
//
//  Created by Jovito Royeca on 08/12/2017.
//
//

import Foundation
import CoreData


extension CMSystem {
    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest<CMSystem>(entityName: "CMSystem") as! NSFetchRequest<NSFetchRequestResult>
    }
    
    @NSManaged public var version: String?
    @NSManaged public var date: NSDate?
    @NSManaged public var description_: String?

}
