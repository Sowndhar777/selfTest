//
//  HomeViewController.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import UIKit
import SDWebImage

class HomeViewController: UIViewController {
    
    // MVVM Data Layer Dependency
    var viewModel = HomeViewModel()
    
    // Storyboard Interface Outlets
    @IBOutlet weak var categoryCollectionView: UICollectionView!
    @IBOutlet weak var recipeTableView: UITableView!
    
    // 🔍 Search (in the nav bar)
    private let searchController = UISearchController(searchResultsController: nil)
    private var searchDebounce: DispatchWorkItem?

    private let loadingIndicatorOverlay = StatefulLoaderView(message: "Syncing recipe feeds...")
    private let UIUIRefreshControlElement = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Explore Hub"
        setupInterfaceLayoutProtocols()
        setupSearchController()
        bindViewModelCallbacksStream()
        
        // Initial programmatic task execution fire
        viewModel.fetchDashboardCategories()
    }
    
    private func setupInterfaceLayoutProtocols() {
        // Bind collection slider
        categoryCollectionView.delegate = self
        categoryCollectionView.dataSource = self
        
        // Bind vertical primary stream list rows
        recipeTableView.delegate = self
        recipeTableView.dataSource = self
        recipeTableView.rowHeight = 110 // Standard row profile bounds size
        
        // Configure native Pull-To-Refresh engine mechanics
        UIUIRefreshControlElement.tintColor = .brandGreen
        UIUIRefreshControlElement.addTarget(self, action: #selector(refreshFeedTriggered), for: .valueChanged)
        recipeTableView.refreshControl = UIUIRefreshControlElement
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search recipes (e.g. pasta, curry)"
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.tintColor = .brandGreen
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func showEmptyMessage(_ message: String?) {
        guard let message = message else {
            recipeTableView.backgroundView = nil
            return
        }
        let label = UILabel()
        label.text = message
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .body)
        recipeTableView.backgroundView = label
    }

    @objc private func refreshFeedTriggered() {
        viewModel.fetchDashboardCategories()
    }
    
    private func bindViewModelCallbacksStream() {
        viewModel.updateProcessingState = { [weak self] isProcessing in
            guard let self = self else { return }
            if isProcessing {
                if !self.UIUIRefreshControlElement.isRefreshing {
                    self.loadingIndicatorOverlay.show(on: self)
                }
            } else {
                self.loadingIndicatorOverlay.hide()
                self.UIUIRefreshControlElement.endRefreshing()
            }
        }
        
        viewModel.reloadCategoriesView = { [weak self] in
            self?.categoryCollectionView.reloadData()
        }
        
        viewModel.updateEmptyMessage = { [weak self] message in
            self?.showEmptyMessage(message)
        }

        viewModel.reloadRecipesStreamView = { [weak self] in
            self?.recipeTableView.reloadData()
        }
        
        viewModel.displayAlertNotice = { [weak self] errorText in
            guard let self = self else { return }
            let notificationView = UIAlertController(title: "Connection Alert", message: errorText, preferredStyle: .alert)
            notificationView.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(notificationView, animated: true)
        }
    }
}

// MARK: - Top Categories Slider Layout Logic (`UICollectionView`)
extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfCategories
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategorySliderCellID", for: indexPath)
        let itemData = viewModel.getCategoryItem(at: indexPath.item)
        
        // Population matching tag mappings placeholders (Tip: Add your custom files to Views subfolder later)
        if let categoryTitle = cell.viewWithTag(201) as? UILabel {
            categoryTitle.text = itemData.strCategory
        }
        
        // Visual indicator shading highlight for active cell cards tracking properties elements
        cell.contentView.layer.cornerRadius = 8
        cell.contentView.backgroundColor = .secondarySurfaceBackground
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Tapping a category leaves search mode
        if searchController.isActive {
            searchController.searchBar.text = ""
            searchController.isActive = false
        }
        let selectedCategoryName = viewModel.getCategoryItem(at: indexPath.item).strCategory
        // Stream dynamic update action filtering trigger cascade blocks
        viewModel.fetchRecipesByCategoryStream(categoryName: selectedCategoryName)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 110, height: 44) // Clean horizontal pill tag layout shapes dimensions bounds
    }
}

// MARK: - Main Content Stream Layout Logic (`UITableView`)
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRecipes
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowCell = tableView.dequeueReusableCell(withIdentifier: "RecipeRowCellID", for: indexPath)
        let recipeData = viewModel.getRecipeItem(at: indexPath.row)

        if let recipeTitleLabel = rowCell.viewWithTag(301) as? UILabel {
            recipeTitleLabel.text = recipeData.strMeal
        }

        // Recipe thumbnail (tag 302) — SDWebImage: memory + disk cache, cancels on reuse
        if let thumbImageView = rowCell.viewWithTag(302) as? UIImageView {
            thumbImageView.layer.cornerRadius = 10
            thumbImageView.clipsToBounds = true
            thumbImageView.contentMode = .scaleAspectFill
            thumbImageView.tintColor = .tertiaryLabel
            thumbImageView.sd_imageTransition = .fade
            thumbImageView.sd_setImage(with: URL(string: recipeData.strMealThumb + "/preview"),
                                       placeholderImage: UIImage(systemName: "photo"))
        }

        return rowCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetedMealItem = viewModel.getRecipeItem(at: indexPath.row)
        
        // Routing sequence step link: Transition over cleanly into Screen 8 Recipe Detailed Overview Canvas Panel
        let detailVC: RecipeDetailViewController = UIStoryboard.instantiateViewController(from: .detail, identifier: "RecipeDetailViewController")
        
        // Pass data references securely over via injection properties variables parameters mapping logic boundaries
        detailVC.targetedMealID = targetedMealItem.idMeal
        detailVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - 🔍 Search
extension HomeViewController: UISearchResultsUpdating, UISearchBarDelegate {

    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text ?? ""

        // Wait 0.4s after typing stops, then call the API (avoids a request per letter)
        searchDebounce?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.viewModel.searchRecipes(query: text)
        }
        searchDebounce = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchDebounce?.cancel()
        viewModel.cancelSearch()
    }
}
