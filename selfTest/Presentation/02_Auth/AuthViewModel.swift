//
//  AuthViewModel.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import Foundation

class AuthViewModel {

    // MARK: - UI Binding Closures
    var updateLoadingState: ((Bool) -> Void)?
    var showErrorMessage: ((String) -> Void)?
    var authenticationDidSuccess: (() -> Void)?
    var registrationDidSuccess: ((String) -> Void)?   // server success message
    var dietPreferenceDidSave: (() -> Void)?
    /// Which field failed validation (Signup highlights it in red + focuses it)
    var invalidFieldDetected: ((AuthField) -> Void)?

    enum AuthField {
        case name, email, password, confirmPassword
    }

    // MARK: - Validation
    func isInputValid(emailString: String, passwordString: String) -> Bool {
        let minimalTrimmedEmail = emailString.trimmingCharacters(in: .whitespacesAndNewlines)

        let emailPatternRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicateTest = NSPredicate(format: "SELF MATCHES %@", emailPatternRegex)
        let isEmailFormattedCorrectly = emailPredicateTest.evaluate(with: minimalTrimmedEmail)

        guard isEmailFormattedCorrectly else {
            showErrorMessage?("Invalid Email Address Format. Please check inputs.")
            return false
        }

        guard passwordString.count >= 6 else {
            showErrorMessage?("Password length criteria error. Minimum 6 characters required.")
            return false
        }

        return true
    }

    // MARK: - Registration rules (one clear message at a time)
    struct PasswordRule {
        let title: String                    // checklist text
        let errorMessage: String             // alert text when it fails
        let isSatisfied: (String) -> Bool
    }

    static let passwordRules: [PasswordRule] = [
        PasswordRule(title: "No spaces",
                     errorMessage: "Password must not contain spaces.") {
            $0.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
        },
        PasswordRule(title: "At least 8 characters",
                     errorMessage: "Password must contain at least 8 characters.") { $0.count >= 8 },
        PasswordRule(title: "At most 64 characters",
                     errorMessage: "Password must not be longer than 64 characters.") { $0.count <= 64 },
        PasswordRule(title: "One uppercase letter (A–Z)",
                     errorMessage: "Password must contain at least one uppercase letter (A–Z).") {
            $0.rangeOfCharacter(from: .uppercaseLetters) != nil
        },
        PasswordRule(title: "One lowercase letter (a–z)",
                     errorMessage: "Password must contain at least one lowercase letter (a–z).") {
            $0.rangeOfCharacter(from: .lowercaseLetters) != nil
        },
        PasswordRule(title: "One number (0–9)",
                     errorMessage: "Password must contain at least one number (0–9).") {
            $0.rangeOfCharacter(from: .decimalDigits) != nil
        },
        PasswordRule(title: "One special character (!@#$…)",
                     errorMessage: "Password must contain at least one special character (e.g. ! @ # $).") {
            $0.rangeOfCharacter(from: CharacterSet.alphanumerics.union(.whitespaces).inverted) != nil
        }
    ]

    private func fail(_ field: AuthField, _ message: String) -> Bool {
        invalidFieldDetected?(field)
        showErrorMessage?(message)
        return false
    }

    private func isValidEmail(_ email: String) -> Bool {
        guard email.count <= 254, !email.contains(".."), !email.hasPrefix("."), !email.contains(" ") else { return false }
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*\\.[A-Za-z]{2,24}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    func isRegistrationInputValid(name: String, email: String, password: String, confirmPassword: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // 1. Name
        if trimmedName.isEmpty {
            return fail(.name, "Please enter your full name.")
        }
        if trimmedName.count < 2 {
            return fail(.name, "Name must contain at least 2 characters.")
        }
        if trimmedName.count > 50 {
            return fail(.name, "Name must not be longer than 50 characters.")
        }
        if trimmedName.rangeOfCharacter(from: .decimalDigits) != nil {
            return fail(.name, "Name must not contain numbers.")
        }
        let allowedNameChars = CharacterSet.letters.union(.whitespaces).union(CharacterSet(charactersIn: ".'-"))
        if trimmedName.rangeOfCharacter(from: allowedNameChars.inverted) != nil {
            return fail(.name, "Name can contain only letters, spaces and . ' -")
        }

        // 2. Email
        if trimmedEmail.isEmpty {
            return fail(.email, "Please enter your email address.")
        }
        if !isValidEmail(trimmedEmail) {
            return fail(.email, "Please enter a valid email address (e.g. name@example.com).")
        }

        // 3. Password
        if password.isEmpty {
            return fail(.password, "Please enter a password.")
        }
        if let brokenRule = Self.passwordRules.first(where: { !$0.isSatisfied(password) }) {
            return fail(.password, brokenRule.errorMessage)
        }
        let lowerPassword = password.lowercased()
        let emailUser = trimmedEmail.components(separatedBy: "@").first ?? ""
        let firstName = trimmedName.split(separator: " ").first.map { String($0).lowercased() } ?? ""
     
        // 4. Confirm password
        if confirmPassword.isEmpty {
            return fail(.confirmPassword, "Please confirm your password.")
        }
        if password != confirmPassword {
            return fail(.confirmPassword, "Passwords do not match.")
        }
        return true
    }

    // MARK: - Login: API first, then local Core Data account
    func performUserLoginTask(emailInput: String, passwordInput: String) {
        let username = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !username.isEmpty else {
            showErrorMessage?("Please enter your username or email.")
            return
        }
        guard !passwordInput.isEmpty else {
            showErrorMessage?("Please enter your password.")
            return
        }
        guard passwordInput.count >= 6 else {
            showErrorMessage?("Password must contain at least 6 characters.")
            return
        }

        updateLoadingState?(true)

        let credentialModelDictionary: [String: Any] = [
            "username": username,
            "password": passwordInput,
            "expiresInMins": 60
        ]
        let binaryPayloadData = try? JSONSerialization.data(withJSONObject: credentialModelDictionary)

        APIManager.shared.request(
            urlString: Endpoints.login,
            method: .post,
            bodyPayload: binaryPayloadData
        ) { [weak self] (result: Result<AuthResponse, NetworkError>) in
            guard let self = self else { return }
            self.updateLoadingState?(false)

            switch result {
            case .success(let authData):
                // 1. API account (DummyJSON)
                UserSession.shared.start(with: authData)
                self.authenticationDidSuccess?()
            case .failure(let error):
                // 2. API rejected -> try the account registered on this device
                if let localSession = LocalAccountStore.shared.authenticate(identifier: username,
                                                                           password: passwordInput) {
                    UserSession.shared.start(with: localSession)
                    self.authenticationDidSuccess?()
                } else {
                    self.handle(error, fallback: "Authentication connection error occurred.")
                }
            }
        }
    }

    // MARK: - Register API (DummyJSON: simulated, user is NOT saved on server)
    func performUserRegistration(name: String, email: String, password: String, confirmPassword: String) {
        guard isRegistrationInputValid(name: name, email: email,
                                       password: password, confirmPassword: confirmPassword) else { return }

        // Already registered on this device?
        if LocalAccountStore.shared.accountExists(email: email.trimmingCharacters(in: .whitespacesAndNewlines)) {
            showErrorMessage?(LocalAccountError.alreadyExists.localizedDescription)
            return
        }

        updateLoadingState?(true)

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameParts = trimmedName.split(separator: " ", maxSplits: 1).map(String.init)
        let username = trimmedEmail.components(separatedBy: "@").first ?? trimmedEmail

        let registerPayload: [String: String] = [
            "firstName": nameParts.first ?? trimmedName,
            "lastName": nameParts.count > 1 ? nameParts[1] : "",
            "username": username,
            "email": trimmedEmail,
            "password": password
        ]
        let binaryPayloadData = try? JSONSerialization.data(withJSONObject: registerPayload)

        APIManager.shared.request(
            urlString: Endpoints.register,
            method: .post,
            bodyPayload: binaryPayloadData
        ) { [weak self] (result: Result<RegisterResponse, NetworkError>) in
            guard let self = self else { return }
            self.updateLoadingState?(false)

            switch result {
            case .success(let response):
                // Save the account on this device (password stored as salted hash)
                let saveResult = LocalAccountStore.shared.register(
                    firstName: nameParts.first ?? trimmedName,
                    lastName: nameParts.count > 1 ? nameParts[1] : "",
                    username: username,
                    email: trimmedEmail,
                    password: password
                )
                switch saveResult {
                case .success:
                    let firstName = response.firstName ?? trimmedName
                    self.registrationDidSuccess?("Welcome, \(firstName)! Log in with \(trimmedEmail) or \(username.lowercased()).")
                case .failure(let localError):
                    self.showErrorMessage?(localError.localizedDescription)
                }
            case .failure(let error):
                self.handle(error, fallback: "Registration failed. Please try again.")
            }
        }
    }

    // MARK: - Save Diet Preference API (DummyJSON: PUT /users/{id})
    func saveDietPreference(_ diet: String) {
        guard let userId = UserSession.shared.userId else {
            showErrorMessage?("Session expired. Please log in again.")
            return
        }

        // Local (device) accounts don't exist on DummyJSON -> save locally only
        if UserSession.shared.accessToken == LocalAccountStore.localSessionToken {
            UserSession.shared.dietPreference = diet
            dietPreferenceDidSave?()
            return
        }

        updateLoadingState?(true)

        let payload: [String: String] = ["dietaryPreference": diet]
        let binaryPayloadData = try? JSONSerialization.data(withJSONObject: payload)

        APIManager.shared.request(
            urlString: Endpoints.updateUser(id: userId),
            method: .put,
            bodyPayload: binaryPayloadData
        ) { [weak self] (result: Result<UserUpdateResponse, NetworkError>) in
            guard let self = self else { return }
            self.updateLoadingState?(false)

            switch result {
            case .success:
                UserSession.shared.dietPreference = diet
                self.dietPreferenceDidSave?()
            case .failure(let error):
                self.handle(error, fallback: "Could not save your preference. Please try again.")
            }
        }
    }

    // MARK: - Error Mapping
    private func handle(_ error: NetworkError, fallback: String) {
        switch error {
        case .decodingError:
            showErrorMessage?("Server data structure parsing mismatch.")
        case .serverError(let textDescription):
            showErrorMessage?(textDescription)
        default:
            showErrorMessage?(fallback)
        }
    }
}
