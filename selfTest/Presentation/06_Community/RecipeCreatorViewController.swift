//
//  RecipeCreatorViewController.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//
//  S13: Recipe Creator (presented modally from Community "+")
//

import UIKit

class RecipeCreatorViewController: UIViewController {

    var viewModel: CommunityViewModel?

    // MARK: - Outlets (Community.storyboard)
    @IBOutlet weak var dishTitleTextField: UITextField!
    @IBOutlet weak var reviewDescriptionTextView: UITextView!
    @IBOutlet weak var publishActionButton: CustomActionButton!

    private let operationalLoaderOverlay = StatefulLoaderView(message: "Publishing your post...")

    // 1–5 star rating (added in code above the Publish button)
    private let ratingControl = UISegmentedControl(items: ["1★", "2★", "3★", "4★", "5★"])

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Share Recipe Log"
        setupTextInputs()
        setupRatingControl()
        setupKeyboardDismiss()
        bindCreatorCallbacks()
    }

    // MARK: - UI Setup
    private func setupTextInputs() {
        dishTitleTextField.delegate = self
        dishTitleTextField.returnKeyType = .next
        dishTitleTextField.autocapitalizationType = .words

        reviewDescriptionTextView.layer.borderColor = UIColor.systemGray4.cgColor
        reviewDescriptionTextView.layer.borderWidth = 1.0
        reviewDescriptionTextView.layer.cornerRadius = 8
        reviewDescriptionTextView.font = .preferredFont(forTextStyle: .body)
        reviewDescriptionTextView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
    }

    private func setupRatingControl() {
        ratingControl.selectedSegmentIndex = 4   // default 5★
        ratingControl.selectedSegmentTintColor = .brandGreen
        ratingControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)

        // Insert "Your rating" + control just above the Publish button (inside the form stack)
        guard let stack = publishActionButton.superview as? UIStackView,
              let index = stack.arrangedSubviews.firstIndex(of: publishActionButton) else { return }

        let ratingLabel = UILabel()
        ratingLabel.text = "Your rating"
        ratingLabel.font = .preferredFont(forTextStyle: .headline)

        stack.insertArrangedSubview(ratingLabel, at: index)
        stack.insertArrangedSubview(ratingControl, at: index + 1)
        stack.setCustomSpacing(20, after: ratingControl)
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - Bindings
    private func bindCreatorCallbacks() {
        viewModel?.updateProcessingOverlay = { [weak self] isUploading in
            guard let self = self else { return }
            self.publishActionButton.isEnabled = !isUploading
            if isUploading {
                self.operationalLoaderOverlay.show(on: self)
            } else {
                self.operationalLoaderOverlay.hide()
            }
        }

        viewModel?.creationOperationDidSuccess = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    // MARK: - Actions
    @IBAction func publishButtonTapped(_ sender: CustomActionButton) {
        view.endEditing(true)
        let titleInputText = dishTitleTextField.text ?? ""
        let descriptionInputText = reviewDescriptionTextView.text ?? ""

        guard !titleInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !descriptionInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            let notice = UIAlertController(title: "Missing Details",
                                           message: "Please enter the dish name and your review.",
                                           preferredStyle: .alert)
            notice.addAction(UIAlertAction(title: "OK", style: .default))
            present(notice, animated: true)
            return
        }

        viewModel?.publishCustomRecipeForm(title: titleInputText,
                                           description: descriptionInputText,
                                           rating: ratingControl.selectedSegmentIndex + 1)
    }

    @IBAction func cancelBarButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITextFieldDelegate
extension RecipeCreatorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        reviewDescriptionTextView.becomeFirstResponder()
        return true
    }
}
