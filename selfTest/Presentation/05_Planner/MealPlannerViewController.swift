//
//  MealPlannerViewController.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import UIKit

class MealPlannerViewController: UIViewController {

    // Shared with Recipe Detail ("Add to Planner") and Grocery List
    var viewModel: PlannerViewModel? = PlannerViewModel.shared

    // MARK: - Outlets (Planner.storyboard)
    @IBOutlet weak var dateSelectionPicker: UIDatePicker!
    @IBOutlet weak var periodSegmentedControl: UISegmentedControl!   // Breakfast, Lunch, Dinner
    @IBOutlet weak var calendarItemsTableView: UITableView!
    @IBOutlet weak var generateGroceryActionButton: CustomActionButton!

    /// Meals for the selected date + slot
    private var visibleMeals: [ScheduledMealItem] = []

    private var selectedPeriod: String {
        periodSegmentedControl.titleForSegment(at: periodSegmentedControl.selectedSegmentIndex) ?? "Breakfast"
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Meal Planner"
        setupTableViewProtocols()
        setupFilterControls()
        bindViewModelCallbacksMatrix()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Just added something from Recipe Detail? Jump to that date/slot.
        if let focus = viewModel?.pendingFocus {
            dateSelectionPicker.date = focus.date
            if let index = (0..<periodSegmentedControl.numberOfSegments)
                .first(where: { periodSegmentedControl.titleForSegment(at: $0) == focus.period }) {
                periodSegmentedControl.selectedSegmentIndex = index
            }
            viewModel?.pendingFocus = nil
        }
        refreshVisibleMeals()
    }

    // MARK: - Setup
    private func setupTableViewProtocols() {
        calendarItemsTableView.delegate = self
        calendarItemsTableView.dataSource = self
    }

    private func setupFilterControls() {
        dateSelectionPicker.datePickerMode = .date
        dateSelectionPicker.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        periodSegmentedControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
    }

    private func bindViewModelCallbacksMatrix() {
        viewModel?.reloadPlannerCalendar = { [weak self] in
            DispatchQueue.main.async { self?.refreshVisibleMeals() }
        }
    }

    @objc private func filterChanged() {
        refreshVisibleMeals()
    }

    private func refreshVisibleMeals() {
        visibleMeals = viewModel?.meals(on: dateSelectionPicker.date, period: selectedPeriod) ?? []
        calendarItemsTableView.reloadData()
        updateEmptyState()

        // Grocery list makes sense only when something is planned
        let hasAnyMeal = (viewModel?.numberOfScheduledMeals ?? 0) > 0
        generateGroceryActionButton.isEnabled = hasAnyMeal
        generateGroceryActionButton.alpha = hasAnyMeal ? 1.0 : 0.5
    }

    private func updateEmptyState() {
        guard visibleMeals.isEmpty else {
            calendarItemsTableView.backgroundView = nil
            return
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        let label = UILabel()
        label.text = "No \(selectedPeriod.lowercased()) planned for \(formatter.string(from: dateSelectionPicker.date)).\nOpen a recipe and tap 📅 to add it here."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .body)
        calendarItemsTableView.backgroundView = label
    }

    // MARK: - Actions
    @IBAction func viewGroceryListTapped(_ sender: CustomActionButton) {
        let groceryVC: GroceryListViewController = UIStoryboard.instantiateViewController(from: .planner, identifier: "GroceryListViewController")
        groceryVC.viewModel = self.viewModel
        groceryVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(groceryVC, animated: true)
    }
}

// MARK: - UITableView
extension MealPlannerViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleMeals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleRowCellID", for: indexPath)
        let data = visibleMeals[indexPath.row]

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        let displayDate = formatter.string(from: data.targetDayDate)

        if let slotLabel = cell.viewWithTag(501) as? UILabel {
            slotLabel.text = "[\(data.mealPeriodSlot.uppercased()) - \(displayDate.uppercased())]"
            slotLabel.textColor = .brandGreen
        }
        if let mealLabel = cell.viewWithTag(502) as? UILabel {
            mealLabel.text = data.recipeTitleName
        }
        cell.selectionStyle = .default
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // Tap a planned dish -> grocery list for ONLY that dish
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let meal = visibleMeals[indexPath.row]
        let groceryVC: GroceryListViewController = UIStoryboard.instantiateViewController(from: .planner, identifier: "GroceryListViewController")
        groceryVC.viewModel = self.viewModel
        groceryVC.focusedPlanID = meal.uniquePlanID
        groceryVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(groceryVC, animated: true)
    }

    // Swipe left -> Remove
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let meal = visibleMeals[indexPath.row]
        let remove = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, done in
            self?.viewModel?.removeScheduledMeal(planID: meal.uniquePlanID)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [remove])
    }
}
