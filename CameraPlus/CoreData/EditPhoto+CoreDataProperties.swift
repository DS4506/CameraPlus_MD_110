import Foundation
import CoreData

extension EditedPhoto {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<EditedPhoto> {
        return NSFetchRequest<EditedPhoto>(entityName: "EditedPhoto")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var filter: String?
    @NSManaged public var intensity: Double
    @NSManaged public var imageData: Data?
}

extension EditedPhoto: Identifiable { }
