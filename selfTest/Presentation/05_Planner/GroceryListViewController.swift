//
//  GroceryListViewController.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//
//  S11: Shopping Ledger — ingredients grouped per planned dish.
//

import UIKit

class GroceryListViewController: UIViewController {

    var viewModel: PlannerViewModel? = PlannerViewModel.shared

    /// Set this to show only one dish's grocery list (from Meal Planner row tap).
    /// nil = all dishes ("View Grocery List" button).
    var focusedPlanID: String?

    private var sections: [GrocerySection] = []

    @IBOutlet weak var groceryChecklistTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = focusedPlanID == nil ? "Shopping Ledger" : "Dish Groceries"
        setupLedgerProtocols()
        bindLedgerCallbacks()
    }

    private func setupLedgerProtocols() {
        groceryChecklistTableView.delegate = self
        groceryChecklistTableView.dataSource = self
        groceryChecklistTableView.rowHeight = 54
        groceryChecklistTableView.sectionHeaderTopPadding = 12
    }

    private func bindLedgerCallbacks() {
        viewModel?.reloadGroceryChecklist = { [weak self] in
            DispatchQueue.main.async { self?.refresh() }
        }
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Re-bind: the shared view model's closure may point to another Grocery screen
        bindLedgerCallbacksOnly()
        refresh()
    }

    private func bindLedgerCallbacksOnly() {
        viewModel?.reloadGroceryChecklist = { [weak self] in
            DispatchQueue.main.async { self?.refresh() }
        }
    }

    private func refresh() {
        sections = viewModel?.grocerySections(for: focusedPlanID) ?? []
        groceryChecklistTableView.reloadData()
        updateEmptyState()
    }

    private func updateEmptyState() {
        if sections.reduce(0, { $0 + $1.items.count }) == 0 {
            let label = UILabel()
            label.text = "Your shopping list is empty.\nPlan a meal to generate ingredients."
            label.numberOfLines = 0
            label.textAlignment = .center
            label.textColor = .secondaryLabel
            groceryChecklistTableView.backgroundView = label
        } else {
            groceryChecklistTableView.backgroundView = nil
        }
    }
}

// MARK: - UITableView (one section per dish)
extension GroceryListViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    // Dish header: "BREAKFAST · SEP 28" + recipe name + "2 of 6 bought"
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let group = sections[section]
        let bought = group.items.filter { $0.isChecked }.count

        let slotLabel = UILabel()
        slotLabel.text = group.subtitle
        slotLabel.font = .preferredFont(forTextStyle: .caption1)
        slotLabel.textColor = .brandGreen

        let nameLabel = UILabel()
        nameLabel.text = group.recipeName
        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.numberOfLines = 2

        let progressLabel = UILabel()
        progressLabel.text = "\(bought) of \(group.items.count) bought"
        progressLabel.font = .preferredFont(forTextStyle: .caption1)
        progressLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [slotLabel, nameLabel, progressLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false

        let header = UIView()
        header.backgroundColor = .systemBackground
        header.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: header.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -20)
        ])
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 72
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowCell = tableView.dequeueReusableCell(withIdentifier: "GroceryRowCellID", for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]

        if let nameLabel = rowCell.viewWithTag(601) as? UILabel {
            // Always set BOTH states explicitly (reused cells otherwise keep the old strike-through)
            let attributes: [NSAttributedString.Key: Any] = item.isChecked
                ? [.strikethroughStyle: NSUnderlineStyle.single.rawValue,
                   .foregroundColor: UIColor.secondaryLabel]
                : [.strikethroughStyle: 0,
                   .foregroundColor: UIColor.label]
            nameLabel.attributedText = NSAttributedString(string: item.itemName, attributes: attributes)
        }

        rowCell.accessoryType = item.isChecked ? .checkmark : .none
        rowCell.tintColor = .brandGreen
        return rowCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let group = sections[indexPath.section]
        viewModel?.toggleGroceryItem(planID: group.planID, itemName: group.items[indexPath.row].itemName)
    }
}
