//
//  DetailViewModel.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import Foundation

class DetailViewModel {
    
    // Binding streams to feed content elements straight to view layouts
    var updateProcessingState: ((Bool) -> Void)?
    var reloadRecipeDetails: (() -> Void)?
    var errorNotificationHook: ((String) -> Void)?
    
    // Core isolated properties storage parameters mapping logic structures
    private var activeRecipeDetail: RecipeDetailItem?
    
    // Portion control tracking metrics data parameters boundaries scale tokens
    var baseServingFactor: Int = 2 {
        didSet {
            reloadRecipeDetails?() // Trigger view update immediately upon change
        }
    }
    
    // API Call: Fetch detailed spec matrices by ID reference anchor strings
    func fetchRecipeDetailsContent(recipeID: String) {
        updateProcessingState?(true)
        let trackingLookupURL = "\(Endpoints.recipeLookup)?i=\(recipeID)"
        
        APIManager.shared.request(urlString: trackingLookupURL) { [weak self] (result: Result<RecipeResponse, NetworkError>) in
            guard let self = self else { return }
            self.updateProcessingState?(false)
            
            switch result {
            case .success(let payload):
                self.activeRecipeDetail = payload.meals?.first
                self.reloadRecipeDetails?()
            case .failure(let errorReason):
                switch errorReason {
                case .decodingError:
                    self.errorNotificationHook?("Recipe properties layout parsing configuration mismatch.")
                default:
                    self.errorNotificationHook?("Failed to sync details framework safely.")
                }
            }
        }
    }
    
    // MARK: - Data Interface Source Output Channels
    
    /// Full recipe (used by "Add to Planner")
    var currentRecipe: RecipeDetailItem? {
        return activeRecipeDetail
    }

    var recipeImageURL: String {
        return activeRecipeDetail?.strMealThumb ?? ""
    }

    var recipeTitle: String {
        return activeRecipeDetail?.strMeal ?? "Loading Meal Description..."
    }
    
    var recipeInstructions: String {
        return activeRecipeDetail?.strInstructions ?? "No custom cooking directions specified."
    }
    
    var numberOfIngredients: Int {
        return activeRecipeDetail?.ingredientsList.count ?? 0
    }
    
    // 💡 THE DYNAMIC MATH SCALE ENGINE: Multiplies metrics measurements tokens based on active servings counters
    func getScaledIngredientDetails(at index: Int) -> String {
        guard let item = activeRecipeDetail?.ingredientsList[index] else { return "" }
        
        // Return standard raw lines if calculation patterns fail to match conditions bounds
        let componentIngredient = item.ingredient
        let baselineMeasurementText = item.measurement
        
        return "• \(baselineMeasurementText) \(componentIngredient) (Scaled for \(baseServingFactor) portions)"
    }
}

extension DetailViewModel {
    // Splits a massive block of instruction text into individual clean step strings
    func parseInstructionsIntoSteps(rawText: String) -> [String] {
        let steps = rawText.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        return steps.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
    }
}
