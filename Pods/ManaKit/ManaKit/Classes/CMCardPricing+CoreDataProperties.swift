//
//  CMCardPricing+CoreDataProperties.swift
//  
//
//  Created by Jovito Royeca on 04/11/2017.
//
//

import Foundation
import CoreData


extension CMCardPricing {

    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest<CMCardPricing>(entityName: "CMCardPricing") as! NSFetchRequest<NSFetchRequestResult>
    }
    
    @NSManaged public var id: Int64
    @NSManaged public var low: Double
    @NSManaged public var average: Double
    @NSManaged public var high: Double
    @NSManaged public var foil: Double
    @NSManaged public var lastUpdate: NSDate?
    @NSManaged public var link: String?
    @NSManaged public var card: CMCard?

}
