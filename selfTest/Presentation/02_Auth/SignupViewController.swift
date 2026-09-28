//
//  SignupViewController.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import UIKit

class SignupViewController: UIViewController {

    // Own instance: Login-oda viewModel closures overwrite aagaama irukka
    private let viewModel = AuthViewModel()

    // MARK: - Outlets (Auth.storyboard)
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!

    private let loaderView = StatefulLoaderView(message: "Creating account...")

    // Live password checklist (added under the Password field in code)
    private let passwordRulesLabel = UILabel()
    private let confirmMatchLabel = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Create Profile"
        configureTextFields()
        addPasswordToggle(to: passwordTextField)
        addPasswordToggle(to: confirmPasswordTextField)
        setupLiveValidation()
        configureKeyboardDismiss()
        configureBindings()
    }

    // MARK: - UI Setup
    private func configureTextFields() {
        nameTextField.delegate = self
        nameTextField.textContentType = .name
        nameTextField.autocapitalizationType = .words
        nameTextField.returnKeyType = .next

        emailTextField.delegate = self
        emailTextField.keyboardType = .emailAddress
        emailTextField.textContentType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.spellCheckingType = .no
        emailTextField.returnKeyType = .next

        passwordTextField.delegate = self
        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .newPassword
        passwordTextField.returnKeyType = .next

        confirmPasswordTextField.delegate = self
        confirmPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.textContentType = .newPassword
        confirmPasswordTextField.returnKeyType = .done
    }

    // MARK: - 👁 Password eye toggle
    private func addPasswordToggle(to textField: UITextField) {
        let toggleButton = UIButton(type: .system)
        toggleButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        toggleButton.tintColor = .secondaryLabel
        toggleButton.accessibilityLabel = "Show password"
        toggleButton.frame = CGRect(x: 0, y: 0, width: 40, height: 30)

        toggleButton.addAction(UIAction { [weak textField, weak toggleButton] _ in
            guard let field = textField, let button = toggleButton else { return }
            let wasEditing = field.isFirstResponder
            let currentText = field.text

            field.isSecureTextEntry.toggle()

            // Keep text & cursor when switching secure mode
            field.text = nil
            field.text = currentText
            if wasEditing {
                let end = field.endOfDocument
                field.selectedTextRange = field.textRange(from: end, to: end)
            }

            let hidden = field.isSecureTextEntry
            button.setImage(UIImage(systemName: hidden ? "eye.slash" : "eye"), for: .normal)
            button.accessibilityLabel = hidden ? "Show password" : "Hide password"
        }, for: .touchUpInside)

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 30))
        container.addSubview(toggleButton)
        textField.rightView = container
        textField.rightViewMode = .always
    }

    // MARK: - Live validation (checklist + button enable)
    private func setupLiveValidation() {
        [passwordRulesLabel, confirmMatchLabel].forEach {
            $0.numberOfLines = 0
            $0.font = .preferredFont(forTextStyle: .caption1)
        }

        // Insert labels right under the fields if they live in a stack view
        if let stack = passwordTextField.superview as? UIStackView,
           let index = stack.arrangedSubviews.firstIndex(of: passwordTextField) {
            stack.insertArrangedSubview(passwordRulesLabel, at: index + 1)
        }
        if let stack = confirmPasswordTextField.superview as? UIStackView,
           let index = stack.arrangedSubviews.firstIndex(of: confirmPasswordTextField) {
            stack.insertArrangedSubview(confirmMatchLabel, at: index + 1)
        }

        [nameTextField, emailTextField, passwordTextField, confirmPasswordTextField].forEach {
            $0?.addTarget(self, action: #selector(inputsChanged), for: .editingChanged)
        }
        inputsChanged()
    }

    @objc private func inputsChanged() {
        let password = passwordTextField.text ?? ""
        let confirm = confirmPasswordTextField.text ?? ""

        // ✓ / ✗ checklist
        let checklist = NSMutableAttributedString()
        for (i, rule) in AuthViewModel.passwordRules.enumerated() {
            let ok = rule.isSatisfied(password)
            let line = "\(ok ? "✓" : "○") \(rule.title)" + (i < AuthViewModel.passwordRules.count - 1 ? "\n" : "")
            checklist.append(NSAttributedString(string: line, attributes: [
                .foregroundColor: ok ? UIColor.systemGreen : UIColor.secondaryLabel
            ]))
        }
        passwordRulesLabel.attributedText = checklist
        passwordRulesLabel.isHidden = password.isEmpty

        // Confirm match hint
        if confirm.isEmpty {
            confirmMatchLabel.isHidden = true
        } else {
            let matches = confirm == password
            confirmMatchLabel.isHidden = false
            confirmMatchLabel.text = matches ? "✓ Passwords match" : "✗ Passwords don't match"
            confirmMatchLabel.textColor = matches ? .systemGreen : .systemRed
        }

        // Typing clears the red error border
        [nameTextField, emailTextField, passwordTextField, confirmPasswordTextField].forEach {
            $0?.layer.borderWidth = 0
        }
    }

    private func configureKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - ViewModel Bindings
    private func configureBindings() {
        viewModel.updateLoadingState = { [weak self] isProcessing in
            guard let self = self else { return }
            self.signUpButton?.isEnabled = !isProcessing
            if isProcessing {
                self.loaderView.show(on: self)
            } else {
                self.loaderView.hide()
            }
        }

        viewModel.showErrorMessage = { [weak self] message in
            self?.showAlert(title: "Please check", message: message)
        }

        // Highlight + focus the field that failed
        viewModel.invalidFieldDetected = { [weak self] field in
            guard let self = self else { return }
            let target: UITextField
            switch field {
            case .name:            target = self.nameTextField
            case .email:           target = self.emailTextField
            case .password:        target = self.passwordTextField
            case .confirmPassword: target = self.confirmPasswordTextField
            }
            target.layer.borderColor = UIColor.systemRed.cgColor
            target.layer.borderWidth = 1
            target.layer.cornerRadius = 6
            target.becomeFirstResponder()
        }

        // Alert only after API success
        viewModel.registrationDidSuccess = { [weak self] serverMessage in
            guard let self = self else { return }
            let alert = UIAlertController(title: "Account Created",
                                          message: "\(serverMessage)\nPlease log in.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Go to Login", style: .default) { [weak self] _ in
                self?.navigateBackToLogin()
            })
            self.present(alert, animated: true)
        }
    }

    // MARK: - Actions
    @IBAction func registerButtonTapped(_ sender: UIButton) {
        view.endEditing(true)
        viewModel.performUserRegistration(
            name: nameTextField.text ?? "",
            email: emailTextField.text ?? "",
            password: passwordTextField.text ?? "",
            confirmPassword: confirmPasswordTextField.text ?? ""
        )
    }

    @IBAction func alreadyHaveAccountTapped(_ sender: UIButton) {
        navigateBackToLogin()
    }

    // MARK: - Navigation
    private func navigateBackToLogin() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension SignupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameTextField:     emailTextField.becomeFirstResponder()
        case emailTextField:    passwordTextField.becomeFirstResponder()
        case passwordTextField: confirmPasswordTextField.becomeFirstResponder()
        default:                textField.resignFirstResponder()
        }
        return true
    }
}
