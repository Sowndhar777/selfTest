//
//  RecipeDetailViewController.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import UIKit
import SDWebImage

class RecipeDetailViewController: UIViewController {

    // MVVM
    var viewModel = DetailViewModel()

    // Meal ID passed from Home / Favorites
    var targetedMealID: String?

    // MARK: - Outlets (RecipeDetail.storyboard)
    @IBOutlet weak var scrollViewContainer: UIScrollView!
    @IBOutlet weak var recipeHeroImageView: UIImageView!
    @IBOutlet weak var recipeTitleLabel: UILabel!
    @IBOutlet weak var instructionsTextLabel: UILabel!
    @IBOutlet weak var servingCountLabel: UILabel!
    @IBOutlet weak var ingredientsVerticalStackView: UIStackView!
    @IBOutlet weak var cookingModeButton: CustomActionButton!

    private let favoriteButton = UIBarButtonItem()

    private let operationalSpinnerOverlay = StatefulLoaderView(message: "Unpacking culinary guide...")
    private var heroImageLoaded = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationItems()
        configureCallbackBindingsStream()

        if let trackingID = targetedMealID {
            viewModel.fetchRecipeDetailsContent(recipeID: trackingID)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFavoriteIcon()   // heart may have changed on the Favorites tab
    }

    // MARK: - Nav bar: 📅 Add to Planner
    private func configureNavigationItems() {
        let planButton = UIBarButtonItem(image: UIImage(systemName: "calendar.badge.plus"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(addToPlannerTapped))
        planButton.tintColor = .brandGreen
        planButton.accessibilityLabel = "Add to Planner"
        planButton.isEnabled = false   // enabled after recipe loads

        // ❤️ Save to Favorites
        favoriteButton.image = UIImage(systemName: "heart")
        favoriteButton.style = .plain
        favoriteButton.target = self
        favoriteButton.action = #selector(favoriteTapped)
        favoriteButton.tintColor = .systemRed
        favoriteButton.accessibilityLabel = "Save to Favorites"
        favoriteButton.isEnabled = false

        // Right-most first: 📅 then ❤️
        navigationItem.rightBarButtonItems = [planButton, favoriteButton]
    }

    // MARK: - Bindings
    private func configureCallbackBindingsStream() {
        viewModel.updateProcessingState = { [weak self] isProcessing in
            guard let self = self else { return }
            if isProcessing {
                self.operationalSpinnerOverlay.show(on: self)
            } else {
                self.operationalSpinnerOverlay.hide()
            }
        }

        viewModel.reloadRecipeDetails = { [weak self] in
            self?.populateInterfaceLayoutElements()
        }

        viewModel.errorNotificationHook = { [weak self] errorText in
            let errorSheet = UIAlertController(title: "Lookup Alert", message: errorText, preferredStyle: .alert)
            errorSheet.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self?.present(errorSheet, animated: true)
        }
    }

    private func populateInterfaceLayoutElements() {
        // Hero image only once (servings +/- also triggers this reload)
        if !heroImageLoaded, !viewModel.recipeImageURL.isEmpty {
            heroImageLoaded = true
            loadHeroImage(from: viewModel.recipeImageURL)
        }

        recipeTitleLabel.text = viewModel.recipeTitle
        instructionsTextLabel.text = viewModel.recipeInstructions
        servingCountLabel.text = "Servings: \(viewModel.baseServingFactor) People"
        let isLoaded = viewModel.currentRecipe != nil
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = isLoaded }
        updateFavoriteIcon()

        ingredientsVerticalStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for index in 0..<viewModel.numberOfIngredients {
            let itemLabel = UILabel()
            itemLabel.text = viewModel.getScaledIngredientDetails(at: index)
            itemLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            itemLabel.numberOfLines = 0
            itemLabel.textColor = .secondaryLabel
            ingredientsVerticalStackView.addArrangedSubview(itemLabel)
        }
    }

    private func loadHeroImage(from urlString: String) {
        recipeHeroImageView.contentMode = .scaleAspectFill
        recipeHeroImageView.clipsToBounds = true
        recipeHeroImageView.layer.cornerRadius = 12
        recipeHeroImageView.tintColor = .tertiaryLabel
        recipeHeroImageView.sd_imageTransition = .fade
        recipeHeroImageView.sd_setImage(with: URL(string: urlString),
                                        placeholderImage: UIImage(systemName: "photo"))
    }

    // MARK: - Actions
    @IBAction func increaseServingTapped(_ sender: UIButton) {
        viewModel.baseServingFactor += 1
    }

    @IBAction func decreaseServingTapped(_ sender: UIButton) {
        if viewModel.baseServingFactor > 1 {
            viewModel.baseServingFactor -= 1
        }
    }

    @IBAction func startCookingButtonTapped(_ sender: CustomActionButton) {
        let cookingVC: GuidedCookingViewController = UIStoryboard.instantiateViewController(from: .detail, identifier: "GuidedCookingViewController")
        cookingVC.instructionsRawText = viewModel.recipeInstructions
        navigationController?.pushViewController(cookingVC, animated: true)
    }

    // MARK: - ❤️ Favorites
    private func updateFavoriteIcon() {
        guard let recipe = viewModel.currentRecipe else { return }
        let saved = ProfileViewModel.isFavorite(idMeal: recipe.idMeal)
        favoriteButton.image = UIImage(systemName: saved ? "heart.fill" : "heart")
        favoriteButton.accessibilityLabel = saved ? "Remove from Favorites" : "Save to Favorites"
    }

    @objc private func favoriteTapped() {
        guard let recipe = viewModel.currentRecipe else { return }
        if ProfileViewModel.isFavorite(idMeal: recipe.idMeal) {
            ProfileViewModel.removeFavorite(idMeal: recipe.idMeal)
        } else {
            ProfileViewModel.addFavorite(recipe)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        updateFavoriteIcon()
    }

    @objc private func addToPlannerTapped() {
        guard let recipe = viewModel.currentRecipe else { return }

        let sheet = AddToPlannerSheetViewController(recipeName: recipe.strMeal)
        sheet.onAdd = { [weak self] date, period in
            PlannerViewModel.shared.addRecipeToCalendarSchedule(date: date, period: period, recipe: recipe)
            self?.showAddedConfirmation(date: date, period: period)
        }
        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.medium()]
            presentation.prefersGrabberVisible = true
        }
        present(sheet, animated: true)
    }

    private func showAddedConfirmation(date: Date, period: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        let alert = UIAlertController(title: "Added to Planner",
                                      message: "\(viewModel.recipeTitle)\n\(period) · \(formatter.string(from: date))",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open Meal Planner", style: .default) { [weak self] _ in
            self?.tabBarController?.selectedIndex = 1   // Planner tab
        })
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - Add to Planner bottom sheet (code-only, no storyboard)
final class AddToPlannerSheetViewController: UIViewController {

    var onAdd: ((Date, String) -> Void)?

    private let recipeName: String
    private let datePicker = UIDatePicker()
    private let slotControl = UISegmentedControl(items: ["Breakfast", "Lunch", "Dinner"])

    init(recipeName: String) {
        self.recipeName = recipeName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "Add to Planner"
        titleLabel.font = .boldSystemFont(ofSize: 22)

        let recipeLabel = UILabel()
        recipeLabel.text = recipeName
        recipeLabel.textColor = .secondaryLabel
        recipeLabel.numberOfLines = 2

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.minimumDate = Calendar.current.startOfDay(for: Date())

        let dateRow = UIStackView(arrangedSubviews: [makeLabel("Date"), datePicker])
        dateRow.axis = .horizontal
        dateRow.distribution = .equalSpacing

        // Default slot by time of day
        let hour = Calendar.current.component(.hour, from: Date())
        slotControl.selectedSegmentIndex = hour < 11 ? 0 : (hour < 16 ? 1 : 2)

        var config = UIButton.Configuration.filled()
        config.title = "Add to Planner"
        config.baseBackgroundColor = .brandGreen
        config.cornerStyle = .large
        let addButton = UIButton(configuration: config)
        addButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, recipeLabel, dateRow, slotControl, addButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.setCustomSpacing(4, after: titleLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func makeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }

    @objc private func addTapped() {
        let period = slotControl.titleForSegment(at: slotControl.selectedSegmentIndex) ?? "Lunch"
        let date = datePicker.date
        dismiss(animated: true) { [onAdd] in
            onAdd?(date, period)
        }
    }
}
