//
//  Recipe.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import Foundation

// Root array mapping payload bounds matching lookups and discovery feeds
struct RecipeResponse: Codable {
    let meals: [RecipeDetailItem]?
}

struct RecipeDetailItem: Codable {
    let idMeal: String
    let strMeal: String
    let strCategory: String?
    let strArea: String?
    let strInstructions: String?
    let strMealThumb: String
    let strTags: String?
    let strYoutube: String?
    
    // Flattened structural properties mapping raw contract lines
    let strIngredient1: String?
    let strIngredient2: String?
    let strIngredient3: String?
    let strIngredient4: String?
    let strIngredient5: String?
    let strIngredient6: String?
    let strIngredient7: String?
    let strIngredient8: String?
    let strIngredient9: String?
    let strIngredient10: String?
    
    let strMeasure1: String?
    let strMeasure2: String?
    let strMeasure3: String?
    let strMeasure4: String?
    let strMeasure5: String?
    let strMeasure6: String?
    let strMeasure7: String?
    let strMeasure8: String?
    let strMeasure9: String?
    let strMeasure10: String?
    
    // Computed property array to transform messy API lists into clean loops inside our ViewModels
    var ingredientsList: [(ingredient: String, measurement: String)] {
        var list: [(String, String)] = []
        
        let ingredients = [strIngredient1, strIngredient2, strIngredient3, strIngredient4, strIngredient5, strIngredient6, strIngredient7, strIngredient8, strIngredient9, strIngredient10]
        let measurements = [strMeasure1, strMeasure2, strMeasure3, strMeasure4, strMeasure5, strMeasure6, strMeasure7, strMeasure8, strMeasure9, strMeasure10]
        
        for (index, ingredient) in ingredients.enumerated() {
            if let ing = ingredient, !ing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let meas = measurements[index] ?? "To taste"
                list.append((ing, meas))
            }
        }
        return list
    }
}
