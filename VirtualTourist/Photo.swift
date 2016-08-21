import CoreData

class Photo : NSManagedObject {
    
    // Keys of dict used to create new Photo
    struct Keys {
        static let Key = "key"
        static let ImageData = "imagedata"
        static let Pin = "pin"
    }
    // Photo vars
     @NSManaged var key: String
     @NSManaged var imageData: NSData?  // image can be nil if image not yet loaded
     @NSManaged var pin: Pin
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // create Photo processing
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        key = dictionary[Keys.Key] as! String
        if dictionary[Keys.ImageData] != nil {
            print("imagedata not nil")
            imageData = dictionary[Keys.ImageData] as? NSData
        }
        pin = dictionary[Keys.Pin] as! Pin
        
    }
    
}
