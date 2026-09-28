//
//  Endpoints.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import Foundation

struct Endpoints {
    // Core base endpoint nodes matrix
    private static let mealDBBase = "https://www.themealdb.com/api/json/v1/1"
    private static let authBase = "https://dummyjson.com"   // Free test API (no real backend yet)
    
    // Explicit runtime route endpoints configurations
    static let login = "\(authBase)/auth/login"
    static let register = "\(authBase)/users/add"
    static func updateUser(id: Int) -> String { "\(authBase)/users/\(id)" }
    static let categories = "\(mealDBBase)/categories.php"
    static let filterByCategory = "\(mealDBBase)/filter.php"
    static let recipeLookup = "\(mealDBBase)/lookup.php"
    static let searchRecipes = "\(mealDBBase)/search.php"
}
