import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let modelName = "CameraPlusModel"

        // Load compiled model (.momd) explicitly
        let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd")
        let model: NSManagedObjectModel

        if let url = modelURL, let loaded = NSManagedObjectModel(contentsOf: url) {
            model = loaded
        } else if let merged = NSManagedObjectModel.mergedModel(from: [Bundle.main]) {
            model = merged
            #if DEBUG
            print("⚠️ Using merged model fallback. Check your .xcdatamodeld name.")
            #endif
        } else {
            fatalError("❌ Core Data model could not be loaded from bundle.")
        }

        container = NSPersistentContainer(name: modelName, managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("❌ Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        // Debug list of entities (fixed typing)
        #if DEBUG
        let entityNames = container.managedObjectModel.entities
            .compactMap { $0.name }
            .joined(separator: ", ")
        print("✅ Loaded model with entities: [\(entityNames)]")
        #endif
    }
}
