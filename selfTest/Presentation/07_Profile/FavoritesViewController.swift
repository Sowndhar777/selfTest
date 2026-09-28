//
//  FavoritesViewController.swift
//  selfTest
//
//  S14: Saved Favorites (Profile tab)
//

import UIKit

class FavoritesViewController: UIViewController {

    // MVVM data layer (favorites list lives in ProfileViewModel)
    var viewModel: ProfileViewModel? = ProfileViewModel()

    // MARK: - Outlets (Profile.storyboard)
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var favoritesCollectionView: UICollectionView!

    private let cellID = "FavoriteRecipeCell"
    private let refreshControl = UIRefreshControl()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Saved Favorites"
        configureSettingsButton()

        titleLabel?.text = "Your Saved Recipes"
        subtitleLabel?.text = "Recipes you've saved for later"

        favoritesCollectionView.delegate = self
        favoritesCollectionView.dataSource = self

        // 🔄 Pull to refresh
        refreshControl.tintColor = .brandGreen
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        favoritesCollectionView.refreshControl = refreshControl
        favoritesCollectionView.alwaysBounceVertical = true

        bindViewModel()
        updateEmptyState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel?.reloadFavorites()      // pick up hearts saved from Recipe Detail
        favoritesCollectionView.reloadData()
        updateEmptyState()
    }

    @objc private func pullToRefresh() {
        viewModel?.reloadFavorites()
        refreshControl.endRefreshing()
    }

    // MARK: - Settings (S15 Account Manager)
    private func configureSettingsButton() {
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gearshape"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(openSettings))
        settingsButton.tintColor = .brandGreen
        settingsButton.accessibilityLabel = "Account Settings"
        navigationItem.rightBarButtonItem = settingsButton
    }

    @objc private func openSettings() {
        let settingsVC: ProfileSettingsViewController = UIStoryboard.instantiateViewController(from: .profile, identifier: "ProfileSettingsViewController")
        settingsVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(settingsVC, animated: true)
    }

    // MARK: - Bindings
    private func bindViewModel() {
        viewModel?.refreshFavoritesView = { [weak self] in
            DispatchQueue.main.async {
                self?.favoritesCollectionView.reloadData()
                self?.updateEmptyState()
            }
        }
    }

    // MARK: - Empty State
    private func updateEmptyState() {
        let isEmpty = (viewModel?.numberOfFavoriteRecipes ?? 0) == 0
        if isEmpty {
            let label = UILabel()
            label.text = "No saved recipes yet.\nTap the heart on a recipe to save it."
            label.numberOfLines = 0
            label.textAlignment = .center
            label.textColor = .secondaryLabel
            label.font = .preferredFont(forTextStyle: .body)
            favoritesCollectionView.backgroundView = label
        } else {
            favoritesCollectionView.backgroundView = nil
        }
    }

    // MARK: - Actions
    private func removeFavorite(idMeal: String) {
        // Look up the current index at tap time (indexPath captured in the cell can be stale)
        guard let viewModel = viewModel else { return }
        for index in 0..<viewModel.numberOfFavoriteRecipes
        where viewModel.getFavoriteItem(at: index).idMeal == idMeal {
            viewModel.deleteRecipeFromFavoritesList(at: index)   // triggers refreshFavoritesView
            return
        }
    }
}

// MARK: - UICollectionView DataSource / Delegate / Layout
extension FavoritesViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.numberOfFavoriteRecipes ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dequeued = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath)
        guard let cell = dequeued as? FavoriteRecipeCell,
              let meal = viewModel?.getFavoriteItem(at: indexPath.item) else {
            print("⚠️ FavoriteRecipeCell class not set on the cell in Profile.storyboard")
            return dequeued
        }

        cell.configure(with: meal, isFavorite: true)
        cell.onFavoriteTapped = { [weak self] in
            self?.removeFavorite(idMeal: meal.idMeal)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 32
        return CGSize(width: width, height: 220)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }

    // Tap card -> S8 Recipe Detail
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let meal = viewModel?.getFavoriteItem(at: indexPath.item) else { return }
        let detailVC: RecipeDetailViewController = UIStoryboard.instantiateViewController(from: .detail, identifier: "RecipeDetailViewController")
        detailVC.targetedMealID = meal.idMeal
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
