//
//  FavoriteRecipeCell.swift
//  selfTest
//
//  Custom cell for Saved Favorites (image + title + subtitle + heart)
//  Images: SDWebImage (memory + disk cache, auto-cancel on reuse)
//

import UIKit
import SDWebImage

class FavoriteRecipeCell: UICollectionViewCell {

    @IBOutlet weak var recipeImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!      // "Area • Category"
    @IBOutlet weak var favoriteButton: UIButton!    // heart icon

    var onFavoriteTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        recipeImageView.sd_cancelCurrentImageLoad()
        recipeImageView.image = UIImage(systemName: "photo")
        onFavoriteTapped = nil
    }

    private func setupUI() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        recipeImageView.contentMode = .scaleAspectFill
        recipeImageView.clipsToBounds = true
        recipeImageView.tintColor = .tertiaryLabel
        recipeImageView.sd_imageTransition = .fade
    }

    func configure(with meal: RecipeDetailItem, isFavorite: Bool) {
        titleLabel.text = meal.strMeal

        let area = meal.strArea ?? ""
        let category = meal.strCategory ?? ""
        subtitleLabel.text = [area, category].filter { !$0.isEmpty }.joined(separator: " • ")

        recipeImageView.sd_setImage(with: URL(string: meal.strMealThumb),
                                    placeholderImage: UIImage(systemName: "photo"))

        let heartImage = isFavorite ? "heart.fill" : "heart"
        favoriteButton.setImage(UIImage(systemName: heartImage), for: .normal)
        favoriteButton.tintColor = .systemRed
    }

    @IBAction func heartButtonTapped(_ sender: UIButton) {
        onFavoriteTapped?()
    }
}
