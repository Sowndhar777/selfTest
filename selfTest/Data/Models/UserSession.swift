//
//  UserSession.swift
//  selfTest
//
//  Logged-in user state shared across screens.
//  • Session (incl. access token) -> Keychain (secure, survives app restart)
//  • Diet preference / onboarding flag -> UserDefaults (non-sensitive)
//

import Foundation

final class UserSession {

    static let shared = UserSession()

    private let dietKey = "user.dietPreference"
    private let onboardingKey = "app.hasCompletedOnboarding"
    private let sessionKeychainKey = "user.session"
    private let hasLaunchedKey = "app.hasLaunchedBefore"
    private let displayNameKey = "user.displayName"

    private(set) var userId: Int?
    private(set) var firstName: String?
    private(set) var lastName: String?
    private(set) var username: String?
    private(set) var email: String?
    private(set) var accessToken: String?

    var isLoggedIn: Bool { userId != nil && accessToken != nil }

    /// Non-sensitive preference
    var dietPreference: String? {
        didSet { UserDefaults.standard.set(dietPreference, forKey: dietKey) }
    }

    /// Name shown on Profile / Settings (UserDefaults — not sensitive, no token here)
    var savedDisplayName: String? {
        UserDefaults.standard.string(forKey: displayNameKey)
    }

    /// Onboarding is shown only the first time the app is opened
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: onboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: onboardingKey) }
    }

    private init() {
        dietPreference = UserDefaults.standard.string(forKey: dietKey)
    }

    // MARK: - Login
    func start(with auth: AuthResponse) {
        apply(auth)
        saveDisplayName(from: auth)
        // Save the whole session securely for auto-login
        if let data = try? JSONEncoder().encode(auth) {
            KeychainHelper.save(data, for: sessionKeychainKey)
        }
        PlannerViewModel.shared.reloadForCurrentUser()
    }

    // MARK: - App launch
    /// Returns true if a saved session was found (-> skip login)
    @discardableResult
    func restoreSession() -> Bool {
        // Fresh install? UserDefaults is empty but Keychain may still hold an old session
        if !UserDefaults.standard.bool(forKey: hasLaunchedKey) {
            KeychainHelper.delete(sessionKeychainKey)
            UserDefaults.standard.set(true, forKey: hasLaunchedKey)
            return false
        }

        guard let data = KeychainHelper.read(sessionKeychainKey),
              let auth = try? JSONDecoder().decode(AuthResponse.self, from: data) else {
            return false
        }
        apply(auth)
        if savedDisplayName == nil { saveDisplayName(from: auth) }
        PlannerViewModel.shared.reloadForCurrentUser()
        return true
    }

    // MARK: - Logout
    func clear() {
        KeychainHelper.delete(sessionKeychainKey)
        UserDefaults.standard.removeObject(forKey: displayNameKey)
        userId = nil
        firstName = nil
        lastName = nil
        username = nil
        email = nil
        accessToken = nil
        dietPreference = nil
        // hasCompletedOnboarding stays true (don't show onboarding again after logout)
        PlannerViewModel.shared.reloadForCurrentUser()
    }

    /// "Emily Johnson" (falls back to username)
    private func saveDisplayName(from auth: AuthResponse) {
        let fullName = "\(auth.firstName) \(auth.lastName)".trimmingCharacters(in: .whitespaces)
        let name = fullName.isEmpty ? auth.username : fullName
        UserDefaults.standard.set(name, forKey: displayNameKey)
    }

    private func apply(_ auth: AuthResponse) {
        userId = auth.id
        firstName = auth.firstName
        lastName = auth.lastName
        username = auth.username
        email = auth.email
        accessToken = auth.accessToken
    }
}
