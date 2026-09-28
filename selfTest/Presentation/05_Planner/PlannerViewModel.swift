//
//  PlannerViewModel.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//
//  Meals + grocery ticks are stored in Core Data (RecipeHub):
//  PlannedMeal, GroceryCheck  — per logged-in user.
//

import Foundation
import CoreData

// One dish's grocery block in the Shopping Ledger
struct GrocerySection {
    let planID: String
    let recipeName: String
    let subtitle: String                       // e.g. "BREAKFAST · SEP 28"
    let items: [(itemName: String, isChecked: Bool)]
}

// UI model for one scheduled meal
struct ScheduledMealItem {
    let uniquePlanID: String
    let targetDayDate: Date
    let mealPeriodSlot: String          // Breakfast, Lunch, or Dinner
    let recipeTitleName: String
    let standardRawIngredients: [String]
}

class PlannerViewModel {

    // Shared: Recipe Detail adds meals, Planner & Grocery read the same data
    static let shared = PlannerViewModel()

    // MARK: - Bindings
    var reloadPlannerCalendar: (() -> Void)?
    var reloadGroceryChecklist: (() -> Void)?

    // Planner jumps to this date/slot the next time it appears
    var pendingFocus: (date: Date, period: String)?

    // MARK: - In-memory copy of the current user's data
    private var weeklyScheduledItems: [ScheduledMealItem] = []
    /// Checked grocery keys: "planID|Ingredient" (ticks are per dish)
    private var checkedGroceryKeys = Set<String>()
    /// Grocery list grouped by dish
    private var grocerySections: [GrocerySection] = []

    private let ingredientSeparator = "|"
    private var context: NSManagedObjectContext { CoreDataStack.shared.context }
    private var userKey: String { CoreDataStack.currentUserKey }

    private init() {
        reloadForCurrentUser()
    }

    // MARK: - Load (call after login / logout)
    func reloadForCurrentUser() {
        // Meals
        let mealRequest: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        mealRequest.predicate = NSPredicate(format: "userId == %@", userKey)
        mealRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        let storedMeals = (try? context.fetch(mealRequest)) ?? []

        weeklyScheduledItems = storedMeals.map { meal in
            ScheduledMealItem(
                uniquePlanID: meal.planID ?? UUID().uuidString,
                targetDayDate: meal.date ?? Date(),
                mealPeriodSlot: meal.period ?? "Lunch",
                recipeTitleName: meal.recipeName ?? "",
                standardRawIngredients: (meal.ingredients ?? "")
                    .components(separatedBy: ingredientSeparator)
                    .filter { !$0.isEmpty }
            )
        }

        // Grocery ticks
        let checkRequest: NSFetchRequest<GroceryCheck> = GroceryCheck.fetchRequest()
        checkRequest.predicate = NSPredicate(format: "userId == %@", userKey)
        checkedGroceryKeys = Set(((try? context.fetch(checkRequest)) ?? []).compactMap { $0.itemName })

        rebuildGrocerySections()
        reloadPlannerCalendar?()
    }

    // MARK: - Add / Remove
    func addRecipeToCalendarSchedule(date: Date, period: String, recipe: RecipeDetailItem) {
        let planID = "pln_\(UUID().uuidString.prefix(8))"
        let ingredients = recipe.ingredientsList.map { $0.ingredient }

        // 1. Save to Core Data
        let meal = PlannedMeal(context: context)
        meal.planID = planID
        meal.userId = userKey
        meal.date = date
        meal.period = period
        meal.recipeName = recipe.strMeal
        meal.ingredients = ingredients.joined(separator: ingredientSeparator)
        CoreDataStack.shared.saveContext()

        // 2. Update in-memory list + UI
        weeklyScheduledItems.append(ScheduledMealItem(
            uniquePlanID: planID,
            targetDayDate: date,
            mealPeriodSlot: period,
            recipeTitleName: recipe.strMeal,
            standardRawIngredients: ingredients
        ))
        pendingFocus = (date, period)

        rebuildGrocerySections()
        reloadPlannerCalendar?()
    }

    func removeScheduledMeal(planID: String) {
        let request: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        request.predicate = NSPredicate(format: "planID == %@ AND userId == %@", planID, userKey)
        ((try? context.fetch(request)) ?? []).forEach { context.delete($0) }

        // Remove that dish's grocery ticks too
        let checkRequest: NSFetchRequest<GroceryCheck> = GroceryCheck.fetchRequest()
        checkRequest.predicate = NSPredicate(format: "userId == %@ AND itemName BEGINSWITH %@", userKey, "\(planID)|")
        ((try? context.fetch(checkRequest)) ?? []).forEach { context.delete($0) }
        CoreDataStack.shared.saveContext()

        checkedGroceryKeys = checkedGroceryKeys.filter { !$0.hasPrefix("\(planID)|") }
        weeklyScheduledItems.removeAll { $0.uniquePlanID == planID }
        rebuildGrocerySections()
        reloadPlannerCalendar?()
    }

    // MARK: - Queries
    func meals(on date: Date, period: String) -> [ScheduledMealItem] {
        weeklyScheduledItems.filter {
            Calendar.current.isDate($0.targetDayDate, inSameDayAs: date) && $0.mealPeriodSlot == period
        }
    }

    var numberOfScheduledMeals: Int { weeklyScheduledItems.count }

    func getScheduledMeal(at index: Int) -> ScheduledMealItem {
        weeklyScheduledItems[index]
    }

    // MARK: - Grocery Ledger (grouped per dish)
    private func groceryKey(planID: String, item: String) -> String { "\(planID)|\(item)" }

    private func rebuildGrocerySections() {
        let slotOrder = ["Breakfast": 0, "Lunch": 1, "Dinner": 2]
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"

        let orderedMeals = weeklyScheduledItems.sorted {
            if !Calendar.current.isDate($0.targetDayDate, inSameDayAs: $1.targetDayDate) {
                return $0.targetDayDate < $1.targetDayDate
            }
            return (slotOrder[$0.mealPeriodSlot] ?? 9) < (slotOrder[$1.mealPeriodSlot] ?? 9)
        }

        grocerySections = orderedMeals.map { meal in
            // De-duplicate inside one dish, keep original order
            var seen = Set<String>()
            let names = meal.standardRawIngredients
                .map { $0.trimmingCharacters(in: .whitespaces).capitalized }
                .filter { !$0.isEmpty && seen.insert($0).inserted }

            return GrocerySection(
                planID: meal.uniquePlanID,
                recipeName: meal.recipeTitleName,
                subtitle: "\(meal.mealPeriodSlot.uppercased()) · \(formatter.string(from: meal.targetDayDate).uppercased())",
                items: names.map { name in
                    (itemName: name,
                     isChecked: checkedGroceryKeys.contains(groceryKey(planID: meal.uniquePlanID, item: name)))
                }
            )
        }
        reloadGroceryChecklist?()
    }

    func toggleGroceryItem(section: Int, row: Int) {
        guard grocerySections.indices.contains(section),
              grocerySections[section].items.indices.contains(row) else { return }

        let group = grocerySections[section]
        let key = groceryKey(planID: group.planID, item: group.items[row].itemName)

        if checkedGroceryKeys.contains(key) {
            checkedGroceryKeys.remove(key)
            let request: NSFetchRequest<GroceryCheck> = GroceryCheck.fetchRequest()
            request.predicate = NSPredicate(format: "userId == %@ AND itemName == %@", userKey, key)
            ((try? context.fetch(request)) ?? []).forEach { context.delete($0) }
        } else {
            checkedGroceryKeys.insert(key)
            let check = GroceryCheck(context: context)
            check.userId = userKey
            check.itemName = key
        }
        CoreDataStack.shared.saveContext()
        rebuildGrocerySections()
    }

    /// Toggle using the dish's planID (works for filtered lists too)
    func toggleGroceryItem(planID: String, itemName: String) {
        guard let section = grocerySections.firstIndex(where: { $0.planID == planID }),
              let row = grocerySections[section].items.firstIndex(where: { $0.itemName == itemName }) else { return }
        toggleGroceryItem(section: section, row: row)
    }

    /// All dishes, or only one dish when planID is given
    func grocerySections(for planID: String?) -> [GrocerySection] {
        guard let planID = planID else { return grocerySections }
        return grocerySections.filter { $0.planID == planID }
    }

    var numberOfGrocerySections: Int { grocerySections.count }

    func grocerySection(at index: Int) -> GrocerySection { grocerySections[index] }

    /// Total items across all dishes (used for empty state)
    var numberOfGroceryItems: Int { grocerySections.reduce(0) { $0 + $1.items.count } }
}
