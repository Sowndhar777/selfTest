//
//  CommunityFeedViewController.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//
//  S12: Culinary Feed
//

import UIKit

class CommunityFeedViewController: UIViewController {

    // MVVM
    var viewModel = CommunityViewModel()

    // MARK: - Outlets (Community.storyboard)
    @IBOutlet weak var feedTimelineTableView: UITableView!
    @IBOutlet weak var composeRecipeBarButton: UIBarButtonItem!

    private let refreshControl = UIRefreshControl()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Culinary Feed"   // keeps the tab title unchanged
        setupFeedProtocols()
        bindFeedCallbacksMatrix()
    }

    private func setupFeedProtocols() {
        feedTimelineTableView.delegate = self
        feedTimelineTableView.dataSource = self
        feedTimelineTableView.rowHeight = UITableView.automaticDimension
        feedTimelineTableView.estimatedRowHeight = 130

        // 🔄 Pull to refresh
        refreshControl.tintColor = .brandGreen
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        feedTimelineTableView.refreshControl = refreshControl
    }

    @objc private func pullToRefresh() {
        viewModel.loadPosts()
        refreshControl.endRefreshing()
    }

    private func bindFeedCallbacksMatrix() {
        viewModel.refreshFeedTimeline = { [weak self] in
            guard let self = self else { return }
            self.feedTimelineTableView.reloadData()
            // Show the newest post
            if self.viewModel.numberOfTimelinePosts > 0 {
                self.feedTimelineTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
    }

    // MARK: - Actions
    @IBAction func composeBarButtonTapped(_ sender: UIBarButtonItem) {
        // S13: Recipe Creator (modal)
        let creatorVC: RecipeCreatorViewController = UIStoryboard.instantiateViewController(from: .community, identifier: "RecipeCreatorViewController")
        creatorVC.viewModel = self.viewModel

        let navigationWrapper = UINavigationController(rootViewController: creatorVC)
        present(navigationWrapper, animated: true)
    }
}

// MARK: - UITableView
extension CommunityFeedViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfTimelinePosts
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SocialPostRowCellID", for: indexPath)
        let postData = viewModel.getPostItem(at: indexPath.row)

        if let authorLabel = cell.viewWithTag(701) as? UILabel {
            // Mark your own posts
            let isMine = postData.authorId == CoreDataStack.currentUserKey
            authorLabel.text = isMine ? "\(postData.creatorName) · You" : postData.creatorName
            authorLabel.textColor = .brandGreen
        }
        if let recipeTitleLabel = cell.viewWithTag(702) as? UILabel {
            recipeTitleLabel.text = "cooked: \(postData.recipeTitle)"
        }
        if let reviewContentLabel = cell.viewWithTag(703) as? UILabel {
            reviewContentLabel.text = postData.reviewCommentText
            reviewContentLabel.numberOfLines = 0
        }
        if let starsLabel = cell.viewWithTag(704) as? UILabel {
            starsLabel.text = String(repeating: "⭐", count: postData.ratingStarsCount)
        }

        cell.selectionStyle = .none   // no grey highlight on tap
        return cell
    }

    // 🗑️ Swipe left -> Delete (only your own posts)
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard viewModel.canDeletePost(at: indexPath.row) else { return nil }

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.confirmDelete(at: indexPath, completion: done)
        }
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }

    private func confirmDelete(at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "Delete post?",
                                      message: "This post will be removed from the feed.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completion(false) })
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.deletePost(at: indexPath.row)
            self.feedTimelineTableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        })
        present(alert, animated: true)
    }
}
