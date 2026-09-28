//
//  DietaryWizardViewController.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import UIKit

class DietaryWizardViewController: UIViewController {

    // AuthViewModel dependency injected from LoginViewController
    var viewModel: AuthViewModel?

    // MARK: - Storyboard Outlets
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet var optionButtons: [UIButton]!      // Outlet Collection (tags 0...4)
    @IBOutlet weak var continueButton: UIButton!

    // MARK: - Data
    private let options = ["Vegetarian", "Non-Vegetarian", "Vegan", "Eggetarian", "Keto"]
    private var selectedIndex: Int?
    private lazy var authViewModel = viewModel ?? AuthViewModel()
    private let loaderView = StatefulLoaderView(message: "Saving your preference...")

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Diet Preferences"
        view.backgroundColor = .systemBackground
        setupUI()
        configureBindings()
    }

    // MARK: - UI Setup
    private func setupUI() {
        progressView.progress = 0.33
        titleLabel.text = "What's your diet type?"
        subtitleLabel.text = "We'll personalise your recommendations based on this."

        // Outlet collection order is not guaranteed -> sort by tag
        optionButtons.sort { $0.tag < $1.tag }

        for (index, button) in optionButtons.enumerated() where index < options.count {
            button.setTitle(options[index], for: .normal)
            button.setTitleColor(.label, for: .normal)
            button.contentHorizontalAlignment = .leading
            button.layer.cornerRadius = 12
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemGray4.cgColor
            button.backgroundColor = .secondarySystemBackground
        }

        continueButton.layer.cornerRadius = 12
        updateContinueState()
    }

    private func refreshSelection() {
        for button in optionButtons {
            let isSelected = button.tag == selectedIndex
            button.layer.borderColor = (isSelected ? UIColor.systemGreen : UIColor.systemGray4).cgColor
            button.layer.borderWidth = isSelected ? 2 : 1
            button.backgroundColor = isSelected
                ? UIColor.systemGreen.withAlphaComponent(0.12)
                : .secondarySystemBackground
        }
    }

    private func updateContinueState() {
        let enabled = selectedIndex != nil
        continueButton.isEnabled = enabled
        continueButton.alpha = enabled ? 1.0 : 0.5
    }

    // MARK: - Actions
    @IBAction func optionTapped(_ sender: UIButton) {
        selectedIndex = sender.tag
        refreshSelection()
        updateContinueState()
    }

    @IBAction func continueTapped(_ sender: UIButton) {
        guard let index = selectedIndex else { return }
        // 1. Selected diet -> API (PUT /users/{id}) ; success aana dhan Home open aagum
        authViewModel.saveDietPreference(options[index])
    }

    // MARK: - ViewModel Bindings
    private func configureBindings() {
        authViewModel.updateLoadingState = { [weak self] isProcessing in
            guard let self = self else { return }
            self.continueButton.isEnabled = !isProcessing
            if isProcessing {
                self.loaderView.show(on: self)
            } else {
                self.loaderView.hide()
            }
        }

        authViewModel.showErrorMessage = { [weak self] message in
            let alert = UIAlertController(title: "Alert Notice", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self?.present(alert, animated: true)
        }

        // 2. API success -> Tab bar (Home first tab)
        authViewModel.dietPreferenceDidSave = { [weak self] in
            guard let self = self else { return }
            MainTabBarController.switchAsRoot(from: self.view)
        }
    }
}
