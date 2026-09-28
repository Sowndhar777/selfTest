//
//  HomeViewModel.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import Foundation

class HomeViewModel {
    
    // Asynchronous Component Interface State Closures
    var reloadCategoriesView: (() -> Void)?
    var reloadRecipesStreamView: (() -> Void)?
    var updateProcessingState: ((Bool) -> Void)?
    var displayAlertNotice: ((String) -> Void)?
    /// nil = hide message, otherwise show it in the list (e.g. "No recipes found")
    var updateEmptyMessage: ((String?) -> Void)?
    
    // Core Isolated Data Repositories
    private var categoricalItems: [MealCategory] = []
    private var matchingRecipeItems: [RecipeDetailItem] = []

    // Search state
    private var categoryRecipesBackup: [RecipeDetailItem] = []
    private(set) var isSearching = false
    private var latestSearchQuery = ""
    
    // MARK: - API Orchestrator Actions
    
    // Fetch top horizontal slider cards
    func fetchDashboardCategories() {
        updateProcessingState?(true)
        
        APIManager.shared.request(urlString: Endpoints.categories) { [weak self] (result: Result<CategoryResponse, NetworkError>) in
            guard let self = self else { return }
            self.updateProcessingState?(false)
            
            switch result {
            case .success(let payload):
                // Show only categories that match the diet chosen in the Dietary Wizard
                self.categoricalItems = Self.filterCategories(payload.categories,
                                                              forDiet: UserSession.shared.dietPreference)
                self.reloadCategoriesView?()
                
                // Chain reaction: Instantly load recipes for the first category item as default
                if let initialCategoryName = self.categoricalItems.first?.strCategory {
                    self.fetchRecipesByCategoryStream(categoryName: initialCategoryName)
                }
            case .failure(let failureReason):
                self.handleNetworkFailure(failureReason)
            }
        }
    }
    
    // Filter rows below when a category card gets clicked or tapped
    func fetchRecipesByCategoryStream(categoryName: String) {
        updateProcessingState?(true)
        let filteredURLString = "\(Endpoints.filterByCategory)?c=\(categoryName)"
        
        APIManager.shared.request(urlString: filteredURLString) { [weak self] (result: Result<RecipeResponse, NetworkError>) in
            guard let self = self else { return }
            self.updateProcessingState?(false)
            
            switch result {
            case .success(let payload):
                self.matchingRecipeItems = payload.meals ?? []
                self.categoryRecipesBackup = self.matchingRecipeItems
                self.updateEmptyMessage?(self.matchingRecipeItems.isEmpty ? "No recipes in this category." : nil)
                self.reloadRecipesStreamView?()
            case .failure(let failureReason):
                self.handleNetworkFailure(failureReason)
            }
        }
    }
    
    // MARK: - Search (TheMealDB search.php?s=)
    func searchRecipes(query rawQuery: String) {
        // Remove characters that would break the URL query
        let query = rawQuery
            .components(separatedBy: CharacterSet(charactersIn: "&?#=/%"))
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Empty search -> back to the selected category list
        guard query.count >= 2 else {
            cancelSearch()
            return
        }

        isSearching = true
        latestSearchQuery = query
        updateProcessingState?(true)

        let urlString = "\(Endpoints.searchRecipes)?s=\(query)"
        APIManager.shared.request(urlString: urlString) { [weak self] (result: Result<RecipeResponse, NetworkError>) in
            guard let self = self, query == self.latestSearchQuery else { return }   // ignore old responses
            self.updateProcessingState?(false)

            switch result {
            case .success(let payload):
                var results = payload.meals ?? []
                // Respect the diet (e.g. Vegetarian users don't see Beef results)
                if let allowed = Self.allowedCategories(forDiet: UserSession.shared.dietPreference) {
                    results = results.filter { allowed.contains($0.strCategory ?? "") }
                }
                self.matchingRecipeItems = results
                self.reloadRecipesStreamView?()
                self.updateEmptyMessage?(results.isEmpty ? "No recipes found for “\(query)”." : nil)
            case .failure(let failureReason):
                self.handleNetworkFailure(failureReason)
            }
        }
    }

    func cancelSearch() {
        guard isSearching else { return }
        isSearching = false
        latestSearchQuery = ""
        matchingRecipeItems = categoryRecipesBackup
        reloadRecipesStreamView?()
        updateEmptyMessage?(nil)
    }

    /// Diet preference -> allowed TheMealDB categories (in display order).
    /// nil = no restriction (show everything).
    static func allowedCategories(forDiet diet: String?) -> [String]? {
        switch diet {
        case "Vegetarian":     return ["Vegetarian", "Vegan", "Dessert"]
        case "Vegan":          return ["Vegan"]
        case "Eggetarian":     return ["Vegetarian", "Vegan", "Dessert"]
        case "Keto":           return ["Beef", "Chicken", "Lamb", "Pork", "Seafood", "Goat"]
        case "Non-Vegetarian": return nil
        default:               return nil
        }
    }

    /// Keeps only allowed categories (ordered by the diet list). Non-Vegetarian shows all with Chicken first.
    static func filterCategories(_ all: [MealCategory], forDiet diet: String?) -> [MealCategory] {
        guard let allowed = allowedCategories(forDiet: diet) else {
            var everything = all
            if diet == "Non-Vegetarian",
               let index = everything.firstIndex(where: { $0.strCategory == "Chicken" }) {
                everything.insert(everything.remove(at: index), at: 0)
            }
            return everything
        }
        return allowed.compactMap { name in all.first(where: { $0.strCategory == name }) }
    }

    private func handleNetworkFailure(_ error: NetworkError) {
        switch error {
        case .decodingError:
            self.displayAlertNotice?("Server layout parsing configuration error.")
        default:
            self.displayAlertNotice?("Network communication dropped. Check internet stability.")
        }
    }
    
    // MARK: - Data Interface Source Helpers
    
    var numberOfCategories: Int {
        return categoricalItems.count
    }
    
    var numberOfRecipes: Int {
        return matchingRecipeItems.count
    }
    
    func getCategoryItem(at index: Int) -> MealCategory {
        return categoricalItems[index]
    }
    
    func getRecipeItem(at index: Int) -> RecipeDetailItem {
        return matchingRecipeItems[index]
    }
}
