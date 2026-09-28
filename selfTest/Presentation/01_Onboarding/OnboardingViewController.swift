//
//  OnboardingViewController.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import UIKit

class OnboardingViewController: UIViewController {

    // MVVM
    var viewModel = OnboardingViewModel()

    // MARK: - Outlets (Onboarding.storyboard)
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var actionButton: CustomActionButton!

    private var currentPageIndex = 0 {
        didSet {
            pageControl.currentPage = currentPageIndex
            let isLastSlide = currentPageIndex == viewModel.numberOfSlides - 1
            actionButton.setTitle(isLastSlide ? "Get Started" : "Continue", for: .normal)
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUIConfiguration()
    }

    private func setupUIConfiguration() {
        collectionView.delegate = self
        collectionView.dataSource = self

        pageControl.numberOfPages = viewModel.numberOfSlides
        pageControl.currentPage = 0
        pageControl.isUserInteractionEnabled = false   // dots follow swipe / Continue only
    }

    // MARK: - Actions
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        if currentPageIndex < viewModel.numberOfSlides - 1 {
            currentPageIndex += 1
            scrollToSlide(currentPageIndex)
        } else {
            navigateToLogin()
        }
    }

    /// scrollToItem is unreliable when isPagingEnabled = true (iOS 14+ bug),
    /// so scroll by page offset instead. Each page = collection view width.
    private func scrollToSlide(_ index: Int) {
        let pageWidth = collectionView.bounds.width
        guard pageWidth > 0 else { return }
        collectionView.setContentOffset(CGPoint(x: CGFloat(index) * pageWidth, y: 0), animated: true)
    }

    // MARK: - Navigation (Screen 2: Login)
    private func navigateToLogin() {
        let loginVC: LoginViewController = UIStoryboard.instantiateViewController(from: .auth, identifier: "LoginViewController")
        loginVC.viewModel = AuthViewModel()

        guard let currentSceneWindow = view.window else { return }
        currentSceneWindow.rootViewController = UINavigationController(rootViewController: loginVC)
        UIView.transition(with: currentSceneWindow, duration: 0.35, options: .transitionCrossDissolve, animations: nil)
    }
}

// MARK: - UICollectionView
extension OnboardingViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfSlides
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let targetCell = collectionView.dequeueReusableCell(withReuseIdentifier: "OnboardingCellID", for: indexPath)
        let slideData = viewModel.getSlideData(at: indexPath.item)

        if let iconImage = targetCell.viewWithTag(101) as? UIImageView {
            iconImage.image = UIImage(systemName: slideData.imageName)
            iconImage.tintColor = .brandGreen
        }
        if let titleLbl = targetCell.viewWithTag(102) as? UILabel {
            titleLbl.text = slideData.title
        }
        if let descLbl = targetCell.viewWithTag(103) as? UILabel {
            descLbl.text = slideData.description
        }
        return targetCell
    }

    // Full-screen page per slide
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }

    // Swipe finished -> update dots & button
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.width
        guard pageWidth > 0 else { return }
        currentPageIndex = Int(round(scrollView.contentOffset.x / pageWidth))
    }
}
