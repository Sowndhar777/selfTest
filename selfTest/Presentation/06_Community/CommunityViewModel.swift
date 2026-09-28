//
//  CommunityViewModel.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//
//  Posts are stored in Core Data (entity: CommunityPostRecord) so they survive app restarts.
//  Community = everyone on this device, so posts are NOT filtered by user.
//

import Foundation
import CoreData

// UI model for one post on the timeline
struct CommunityPost {
    let postID: String
    let creatorName: String
    let recipeTitle: String
    let reviewCommentText: String
    let ratingStarsCount: Int
    let baseTimeStamp: Date
    let authorId: String
}

class CommunityViewModel {

    // MARK: - Bindings
    var refreshFeedTimeline: (() -> Void)?
    var updateProcessingOverlay: ((Bool) -> Void)?
    var creationOperationDidSuccess: (() -> Void)?

    // MARK: - Data
    private var socialTimelinePosts: [CommunityPost] = []
    private var context: NSManagedObjectContext { CoreDataStack.shared.context }

    init() {
        seedSamplePostsIfNeeded()
        loadPosts()
    }

    // MARK: - Load (newest first)
    func loadPosts() {
        let request: NSFetchRequest<CommunityPostRecord> = CommunityPostRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        let rows = (try? context.fetch(request)) ?? []

        socialTimelinePosts = rows.map { row in
            CommunityPost(
                postID: row.postID ?? UUID().uuidString,
                creatorName: row.creatorName ?? "Chef",
                recipeTitle: row.recipeTitle ?? "",
                reviewCommentText: row.reviewText ?? "",
                ratingStarsCount: Int(row.rating),
                baseTimeStamp: row.createdAt ?? Date(),
                authorId: row.authorId ?? ""
            )
        }
        refreshFeedTimeline?()
    }

    // First launch only: add 2 sample posts so the feed isn't empty
    private func seedSamplePostsIfNeeded() {
        let request: NSFetchRequest<CommunityPostRecord> = CommunityPostRecord.fetchRequest()
        guard ((try? context.count(for: request)) ?? 0) == 0 else { return }

        insertRecord(creator: "Chef Steve", title: "Spicy Garlic Shrimp",
                     review: "Absolutely phenomenal text balancing instructions! Subbed lemon juice for vinegar and it worked marvelously.",
                     rating: 5, date: Date().addingTimeInterval(-7200), authorId: "sample")
        insertRecord(creator: "Priya cooking", title: "Fluffy Berry Pancakes",
                     review: "Followed the portion calculations scaler perfectly for 6 portions. Text weights quantities scaled flawlessly without error.",
                     rating: 4, date: Date().addingTimeInterval(-10800), authorId: "sample")
        CoreDataStack.shared.saveContext()
    }

    private func insertRecord(creator: String, title: String, review: String,
                              rating: Int, date: Date, authorId: String) {
        let record = CommunityPostRecord(context: context)
        record.postID = "pst_\(UUID().uuidString.prefix(8))"
        record.creatorName = creator
        record.recipeTitle = title
        record.reviewText = review
        record.rating = Int16(min(max(rating, 1), 5))
        record.createdAt = date
        record.authorId = authorId
    }

    // MARK: - Publish
    func publishCustomRecipeForm(title: String, description: String, rating: Int) {
        updateProcessingOverlay?(true)

        // Simulated upload delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self else { return }

            self.insertRecord(
                creator: UserSession.shared.firstName ?? "You",
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                review: description.trimmingCharacters(in: .whitespacesAndNewlines),
                rating: rating,
                date: Date(),
                authorId: CoreDataStack.currentUserKey
            )
            CoreDataStack.shared.saveContext()

            self.updateProcessingOverlay?(false)
            self.loadPosts()                       // newest post appears on top
            self.creationOperationDidSuccess?()
        }
    }

    // MARK: - Delete (own posts only)
    func canDeletePost(at index: Int) -> Bool {
        guard socialTimelinePosts.indices.contains(index) else { return false }
        return socialTimelinePosts[index].authorId == CoreDataStack.currentUserKey
    }

    func deletePost(at index: Int) {
        guard canDeletePost(at: index) else { return }
        let postID = socialTimelinePosts[index].postID

        let request: NSFetchRequest<CommunityPostRecord> = CommunityPostRecord.fetchRequest()
        request.predicate = NSPredicate(format: "postID == %@ AND authorId == %@", postID, CoreDataStack.currentUserKey)
        ((try? context.fetch(request)) ?? []).forEach { context.delete($0) }
        CoreDataStack.shared.saveContext()

        socialTimelinePosts.remove(at: index)
    }

    // MARK: - Data for the table
    var numberOfTimelinePosts: Int { socialTimelinePosts.count }

    func getPostItem(at index: Int) -> CommunityPost {
        socialTimelinePosts[index]
    }
}
