//
//  ProfileViewModel.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//
//  Favorites are stored in Core Data (entity: FavoriteRecipe) per logged-in user.
//  Theme (dark mode) is stored in UserDefaults.
//

import Foundation
import UIKit
import CoreData

class ProfileViewModel {

    // MARK: - Bindings
    var refreshFavoritesView: (() -> Void)?
    var themeDidChangeBroadcast: ((Bool) -> Void)?

    // MARK: - Favorites (in-memory copy of Core Data rows)
    private var favoritedRecipesList: [RecipeDetailItem] = []

    init() {
        reloadFavorites()
    }

    // MARK: - Core Data helpers (shared by Detail ❤️ and Favorites screen)
    private static var context: NSManagedObjectContext { CoreDataStack.shared.context }
    private static var userKey: String { CoreDataStack.currentUserKey }

    private static func fetchFavoriteRows(idMeal: String? = nil) -> [FavoriteRecipe] {
        let request: NSFetchRequest<FavoriteRecipe> = FavoriteRecipe.fetchRequest()
        if let idMeal = idMeal {
            request.predicate = NSPredicate(format: "userId == %@ AND idMeal == %@", userKey, idMeal)
        } else {
            request.predicate = NSPredicate(format: "userId == %@", userKey)
        }
        request.sortDescriptors = [NSSortDescriptor(key: "savedAt", ascending: false)]   // newest first
        return (try? context.fetch(request)) ?? []
    }

    static func isFavorite(idMeal: String) -> Bool {
        !fetchFavoriteRows(idMeal: idMeal).isEmpty
    }

    static func addFavorite(_ recipe: RecipeDetailItem) {
        guard !isFavorite(idMeal: recipe.idMeal) else { return }
        let row = FavoriteRecipe(context: context)
        row.userId = userKey
        row.idMeal = recipe.idMeal
        row.strMeal = recipe.strMeal
        row.strCategory = recipe.strCategory
        row.strArea = recipe.strArea
        row.strMealThumb = recipe.strMealThumb
        row.savedAt = Date()
        CoreDataStack.shared.saveContext()
    }

    static func removeFavorite(idMeal: String) {
        fetchFavoriteRows(idMeal: idMeal).forEach { context.delete($0) }
        CoreDataStack.shared.saveContext()
    }

    // MARK: - Favorites screen
    /// Call in viewWillAppear so hearts added from Recipe Detail show up
    func reloadFavorites() {
        favoritedRecipesList = Self.fetchFavoriteRows().map { row in
            RecipeDetailItem(
                idMeal: row.idMeal ?? "",
                strMeal: row.strMeal ?? "",
                strCategory: row.strCategory,
                strArea: row.strArea,
                strInstructions: nil,
                strMealThumb: row.strMealThumb ?? "",
                strTags: nil, strYoutube: nil,
                strIngredient1: nil, strIngredient2: nil, strIngredient3: nil, strIngredient4: nil, strIngredient5: nil,
                strIngredient6: nil, strIngredient7: nil, strIngredient8: nil, strIngredient9: nil, strIngredient10: nil,
                strMeasure1: nil, strMeasure2: nil, strMeasure3: nil, strMeasure4: nil, strMeasure5: nil,
                strMeasure6: nil, strMeasure7: nil, strMeasure8: nil, strMeasure9: nil, strMeasure10: nil
            )
        }
        refreshFavoritesView?()
    }

    func deleteRecipeFromFavoritesList(at index: Int) {
        guard favoritedRecipesList.indices.contains(index) else { return }
        Self.removeFavorite(idMeal: favoritedRecipesList[index].idMeal)
        favoritedRecipesList.remove(at: index)
        refreshFavoritesView?()
    }

    var numberOfFavoriteRecipes: Int {
        favoritedRecipesList.count
    }

    func getFavoriteItem(at index: Int) -> RecipeDetailItem {
        favoritedRecipesList[index]
    }

    // MARK: - Theme (saved in UserDefaults, applied at launch by SceneDelegate)
    private static let darkModeKey = "app.darkModeEnabled"

    static var isDarkModeEnabled: Bool {
        UserDefaults.standard.bool(forKey: darkModeKey)
    }

    static var savedInterfaceStyle: UIUserInterfaceStyle {
        isDarkModeEnabled ? .dark : .light
    }

    func toggleApplicationThemeInterface(isDarkModeActive: Bool) {
        UserDefaults.standard.set(isDarkModeActive, forKey: Self.darkModeKey)
        themeDidChangeBroadcast?(isDarkModeActive)
    }
}
