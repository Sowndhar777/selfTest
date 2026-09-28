//
//  CoreDataStack.swift
//  selfTest
//
//  Created by sowndharrajan on 27/09/26.
//

//
//  CoreDataStack.swift
//  selfTest
//
//  Single Core Data entry point (like a Room database instance).
//  Model file: RecipeHub.xcdatamodeld
//

import CoreData

final class CoreDataStack {

    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    var context: NSManagedObjectContext { container.viewContext }

    private init() {
        container = NSPersistentContainer(name: "RecipeHub")   // must match the .xcdatamodeld file name
        container.loadPersistentStores { _, error in
            if let error = error {
                // Development: crash loudly so model problems are obvious
                fatalError("Core Data store failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("⚠️ Core Data save failed: \(error)")
            context.rollback()
        }
    }

    /// Current logged-in user key ("guest" if not logged in)
    static var currentUserKey: String {
        UserSession.shared.userId.map(String.init) ?? "guest"
    }
}

