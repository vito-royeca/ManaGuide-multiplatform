//
//  CMRule+CoreDataProperties.swift
//  
//
//  Created by Jovito Royeca on 06/08/2017.
//
//

import Foundation
import CoreData


extension CMRule {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CMRule> {
        return NSFetchRequest<CMRule>(entityName: "CMRule")
    }

    @NSManaged public var number: String?
    @NSManaged public var numberOrder: Double
    @NSManaged public var text: String?
    @NSManaged public var parent: CMRule?
    @NSManaged public var children: NSSet?

}

// MARK: Generated accessors for children
extension CMRule {

    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: CMRule)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: CMRule)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSSet)

}
