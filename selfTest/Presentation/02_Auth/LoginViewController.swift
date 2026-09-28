//
//  LoginViewController.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import UIKit

class LoginViewController: UIViewController {

    // Dependency Injection Layer
    var viewModel = AuthViewModel()

    // MARK: - Outlets (Auth.storyboard)
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginActionButton: UIButton!

    private let stateSpinnerOverlay = StatefulLoaderView(message: "Authenticating profile...")

    // Password eye toggle button
    private let passwordToggleButton = UIButton(type: .system)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextFields()
        configurePasswordToggle()
        configureKeyboardDismiss()
        configureBindingCallbacksMatrix()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Login screen-la nav bar hide, Signup-la show aagum
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - UI Setup
    private func configureTextFields() {
        emailTextField.delegate = self
        emailTextField.placeholder = "Enter your email"
        emailTextField.keyboardType = .asciiCapable
        emailTextField.textContentType = .username
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.returnKeyType = .next

        passwordTextField.delegate = self
        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .password
        passwordTextField.returnKeyType = .go
    }

    private func configurePasswordToggle() {
        passwordToggleButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        passwordToggleButton.tintColor = .secondaryLabel
        passwordToggleButton.accessibilityLabel = "Show password"
        passwordToggleButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        passwordToggleButton.frame = CGRect(x: 0, y: 0, width: 40, height: 30)

        // Right padding container so the icon doesn't touch the field edge
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 30))
        container.addSubview(passwordToggleButton)

        passwordTextField.rightView = container
        passwordTextField.rightViewMode = .always
    }

    @objc private func togglePasswordVisibility() {
        let wasFirstResponder = passwordTextField.isFirstResponder
        let currentText = passwordTextField.text

        passwordTextField.isSecureTextEntry.toggle()

        // Secure entry toggle panna text clear aagaama / cursor jump aagaama irukka
        passwordTextField.text = nil
        passwordTextField.text = currentText
        if wasFirstResponder {
            let end = passwordTextField.endOfDocument
            passwordTextField.selectedTextRange = passwordTextField.textRange(from: end, to: end)
        }

        let isHidden = passwordTextField.isSecureTextEntry
        passwordToggleButton.setImage(UIImage(systemName: isHidden ? "eye.slash" : "eye"), for: .normal)
        passwordToggleButton.accessibilityLabel = isHidden ? "Show password" : "Hide password"
    }

    private func configureKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - ViewModel Bindings
    private func configureBindingCallbacksMatrix() {
        // 1. Loading state
        viewModel.updateLoadingState = { [weak self] isProcessing in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.loginActionButton.isEnabled = !isProcessing
                if isProcessing {
                    self.stateSpinnerOverlay.show(on: self)
                } else {
                    self.stateSpinnerOverlay.hide()
                }
            }
        }

        // 2. Validation / error messages
        viewModel.showErrorMessage = { [weak self] validationText in
            DispatchQueue.main.async {
                self?.showAlert(title: "Alert Notice", message: validationText)
            }
        }

        // 3. Success -> Dietary Preferences Wizard
        viewModel.authenticationDidSuccess = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let dynamicWizardVC: DietaryWizardViewController = UIStoryboard.instantiateViewController(from: .auth, identifier: "DietaryWizardViewController")
                dynamicWizardVC.viewModel = self.viewModel
                self.navigationController?.pushViewController(dynamicWizardVC, animated: true)
            }
        }
    }

    // MARK: - Actions
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        view.endEditing(true)
        let currentEmail = emailTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let currentPassword = passwordTextField.text ?? ""
        viewModel.performUserLoginTask(emailInput: currentEmail, passwordInput: currentPassword)
    }

    @IBAction func createAccountTapped(_ sender: UIButton) {
        view.endEditing(true)
        let signupVC: SignupViewController = UIStoryboard.instantiateViewController(from: .auth, identifier: "SignupViewController")
        // Signup uses its own AuthViewModel (Login closures overwrite aagaama irukka)
        navigationController?.pushViewController(signupVC, animated: true)
    }

    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        showAlert(title: "Forgot Password", message: "Password reset feature coming soon.")
    }

    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            loginButtonTapped(loginActionButton)
        }
        return true
    }
}
