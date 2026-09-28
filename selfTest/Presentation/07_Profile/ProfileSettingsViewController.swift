//
//  ProfileSettingsViewController.swift
//  selfTest
//
//  S15: Account Manager (opened from Saved Favorites ⚙️)
//

import UIKit

final class ProfileSettingsViewController: UIViewController {

    // MARK: - ViewModel
    var viewModel = ProfileViewModel()

    // MARK: - Outlets (Profile.storyboard)
    @IBOutlet weak var userNameHeaderLabel: UILabel!
    @IBOutlet weak var themeSwitchControlView: UISwitch!
    @IBOutlet weak var logOutActionButton: UIButton!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Account Settings"
        setupUserNameLabel()
        setupThemeSwitch()
        setupLogoutButton()
        bindSettingsCallbacksStream()
    }

    // MARK: - UI Setup
    private func setupUserNameLabel() {
        // Name comes from UserDefaults (saved at login)
        let name = UserSession.shared.savedDisplayName ?? "Chef"
        userNameHeaderLabel.text = "Welcome, \(name)!"
    }

    private func setupThemeSwitch() {
        themeSwitchControlView.onTintColor = .brandGreen
        // Show the saved choice
        themeSwitchControlView.isOn = ProfileViewModel.isDarkModeEnabled
    }

    private func setupLogoutButton() {
        logOutActionButton.setTitle("Log Out", for: .normal)
        logOutActionButton.setTitleColor(.systemRed, for: .normal)
    }

    // MARK: - Theme
    private func bindSettingsCallbacksStream() {
        viewModel.themeDidChangeBroadcast = { [weak self] isDarkModeActive in
            DispatchQueue.main.async {
                guard let window = self?.view.window else { return }
                UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
                    window.overrideUserInterfaceStyle = isDarkModeActive ? .dark : .light
                }
            }
        }
    }

    @IBAction func themeSwitchStateChanged(_ sender: UISwitch) {
        viewModel.toggleApplicationThemeInterface(isDarkModeActive: sender.isOn)
    }

    // MARK: - Logout
    @IBAction func logOutButtonTapped(_ sender: UIButton) {
        let actionSheet = UIAlertController(
            title: "Log Out",
            message: "Are you sure you want to log out?",
            preferredStyle: .actionSheet
        )
        actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad safety
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }
        present(actionSheet, animated: true)
    }

    private func performLogout() {
        // Clear session (planner switches to "guest" data; the user's saved data stays in Core Data)
        UserSession.shared.clear()
        navigateToLoginScreen()
    }

    // MARK: - Navigation
    private func navigateToLoginScreen() {
        let loginVC: LoginViewController = UIStoryboard.instantiateViewController(from: .auth, identifier: "LoginViewController")
        loginVC.viewModel = AuthViewModel()

        guard let currentWindow = view.window else { return }
        let navigationController = UINavigationController(rootViewController: loginVC)

        UIView.transition(with: currentWindow, duration: 0.3, options: .transitionCrossDissolve, animations: {
            currentWindow.rootViewController = navigationController
        })
    }
}
