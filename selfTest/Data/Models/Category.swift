import Foundation

// Root response block wrapper matching API data array boundaries
struct CategoryResponse: Codable {
    let categories: [MealCategory]
}

// Singular Category structural layout parameters data properties
struct MealCategory: Codable {
    let idCategory: String
    let strCategory: String
    let strCategoryThumb: String
    let strCategoryDescription: String
}
