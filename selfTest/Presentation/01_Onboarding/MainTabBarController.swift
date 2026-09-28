//
//  MainTabBarController.swift
//  selfTest
//
//  TAB NAVIGATION STRUCTURAL SWITCHER
//  S5 Home | S10 Planner | S12 Community | S14 Favorites
//

import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = .brandGreen
        viewControllers = [
            makeTab(.home, id: "HomeViewController", title: "Explore", icon: "house.fill"),
            makeTab(.planner, id: "MealPlannerViewController", title: "Meal Planner", icon: "calendar"),
            makeTab(.community, id: "CommunityFeedViewController", title: "Community", icon: "person.3.fill"),
            makeTab(.profile, id: "FavoritesViewController", title: "Favorites", icon: "heart.fill")
        ]
    }

    private func makeTab(_ storyboard: UIStoryboard.StoryboardType,
                         id: String, title: String, icon: String) -> UINavigationController {
        let rootVC: UIViewController = UIStoryboard.instantiateViewController(from: storyboard, identifier: id)
        rootVC.title = title
        let nav = UINavigationController(rootViewController: rootVC)
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: icon), tag: 0)
        return nav
    }

    /// Replaces the whole window root (no back button to Login / Wizard)
    static func switchAsRoot(from view: UIView) {
        guard let window = view.window else { return }
        window.rootViewController = MainTabBarController()
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve, animations: nil)
    }
}
