//
//  GuidedCookingViewController.swift
//  selfTest
//
//  Created by sowndharrajan on 20/09/26.
//

import UIKit

class GuidedCookingViewController: UIViewController {
    
    // Core data streams passed directly downstream via injection
    var instructionsRawText: String?
    private var cookingStepsArray: [String] = []
    
    // Storyboard Interface Outlets
    @IBOutlet weak var stepsCollectionView: UICollectionView!
    @IBOutlet weak var stepsProgressView: UIProgressView!
    @IBOutlet weak var progressStepLabel: UILabel!
    @IBOutlet weak var nextStepActionButton: CustomActionButton!
    
    private var currentActiveStepIndex = 0 {
        didSet {
            updateProgressMetricsIndicator()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Guided Cooking"
        prepareCookingStepsDataset()
        setupCollectionViewProtocols()
    }
    
    private func prepareCookingStepsDataset() {
        guard let text = instructionsRawText else { return }
        // Parse raw string block data instantly into standalone step elements arrays
        let helperViewModel = DetailViewModel()
        cookingStepsArray = helperViewModel.parseInstructionsIntoSteps(rawText: text)
        
        if cookingStepsArray.isEmpty {
            cookingStepsArray = ["Carefully review ingredients list and prepare preparation tools to begin."]
        }
    }
    
    private func setupCollectionViewProtocols() {
        stepsCollectionView.delegate = self
        stepsCollectionView.dataSource = self
        
        // Initial setup for the linear indicator meters
        stepsProgressView.progressTintColor = .brandGreen
        updateProgressMetricsIndicator()
    }
    
    private func updateProgressMetricsIndicator() {
        guard !cookingStepsArray.isEmpty else { return }
        
        // Calculate standard fractional progress parameters variables tokens
        let completedRatioFactor = Float(currentActiveStepIndex + 1) / Float(cookingStepsArray.count)
        stepsProgressView.setProgress(completedRatioFactor, animated: true)
        
        progressStepLabel.text = "Step \(currentActiveStepIndex + 1) of \(cookingStepsArray.count)"
        
        // Toggle the title text string label of the action indicator button on the final page card
        if currentActiveStepIndex == cookingStepsArray.count - 1 {
            nextStepActionButton.setTitle("Finish Cooking", for: .normal)
        } else {
            nextStepActionButton.setTitle("Next Step", for: .normal)
        }
    }
    
    // MARK: - Action Control Interaction Event Triggers
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        if currentActiveStepIndex < cookingStepsArray.count - 1 {
            currentActiveStepIndex += 1
            scrollToStep(currentActiveStepIndex)
        } else {
            // Cooking completed -> back to root dashboard
            let celebrationSheet = UIAlertController(title: "Congratulations!", message: "You have completed preparing this custom meal!", preferredStyle: .alert)
            celebrationSheet.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak self] _ in
                self?.navigationController?.popToRootViewController(animated: true)
            }))
            self.present(celebrationSheet, animated: true)
        }
    }

    /// scrollToItem is unreliable when isPagingEnabled = true (iOS 14+ bug),
    /// so scroll by page offset instead. Each page = collection view width.
    private func scrollToStep(_ index: Int) {
        let pageWidth = stepsCollectionView.bounds.width
        guard pageWidth > 0 else { return }
        stepsCollectionView.setContentOffset(CGPoint(x: CGFloat(index) * pageWidth, y: 0), animated: true)
    }
}

// MARK: - Horizontally Paged Collection Processing Layout Engine Protocols
extension GuidedCookingViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cookingStepsArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cardCell = collectionView.dequeueReusableCell(withReuseIdentifier: "StepInstructionCellID", for: indexPath)
        let primaryStepTextString = cookingStepsArray[indexPath.item]
        
        // Populate step card content elements safely via numeric identifier tag mappings configurations
        if let stepNumberLabel = cardCell.viewWithTag(401) as? UILabel {
            stepNumberLabel.text = "STEP \(indexPath.item + 1)"
            stepNumberLabel.textColor = .brandGreen
        }
        if let mainInstructionLabel = cardCell.viewWithTag(402) as? UILabel {
            mainInstructionLabel.text = primaryStepTextString
            mainInstructionLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            mainInstructionLabel.numberOfLines = 0
            mainInstructionLabel.textAlignment = .center
        }
        
        // Add card border visual indicators parameters layers configuration tokens
        cardCell.contentView.layer.cornerRadius = 16
        cardCell.contentView.backgroundColor = .secondarySurfaceBackground
        
        return cardCell
    }
    
    // Card = page width - 32 (16 gap each side). With 16 left/right insets and 32 line spacing,
    // every card starts exactly one page apart -> paging snaps correctly.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width - 32, height: collectionView.bounds.height - 40)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 32
    }

    // Real-time tracking alignment index checks when users manually swipe horizontally across panels
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentHorizontalOffset = scrollView.contentOffset.x
        let boundaryWidthDimension = scrollView.frame.width
        if boundaryWidthDimension > 0 {
            currentActiveStepIndex = Int(round(currentHorizontalOffset / boundaryWidthDimension))
        }
    }
}
