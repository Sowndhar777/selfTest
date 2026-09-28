//
//  SceneDelegate.swift
//  selfTest
//
//  S1: Launch routing
//  • First launch            -> Onboarding
//  • Saved session (Keychain) -> Main tabs (auto-login)
//  • Otherwise               -> Login
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = ProfileViewModel.savedInterfaceStyle   // saved dark / light mode

        window.rootViewController = makeInitialViewController()
        self.window = window
        window.makeKeyAndVisible()
    }

    // MARK: - Routing
    private func makeInitialViewController() -> UIViewController {
        let userSession = UserSession.shared

        // 1. Logged in before? -> straight to the app
        if userSession.restoreSession() {
            return MainTabBarController()
        }

        // 2. First time? -> Onboarding
        if !userSession.hasCompletedOnboarding {
            let onboardingVC: OnboardingViewController = UIStoryboard.instantiateViewController(from: .onboarding, identifier: "OnboardingViewController")
            return onboardingVC
        }

        // 3. Seen onboarding, not logged in -> Login
        let loginVC: LoginViewController = UIStoryboard.instantiateViewController(from: .auth, identifier: "LoginViewController")
        loginVC.viewModel = AuthViewModel()
        return UINavigationController(rootViewController: loginVC)
    }
}
